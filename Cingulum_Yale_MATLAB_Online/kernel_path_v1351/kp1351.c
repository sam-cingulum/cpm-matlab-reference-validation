/* kp1351.c — V1351 original-only large-row dgemm summation-order probe.
 *
 * A plain MEX gateway onto the BLAS/LAPACK that MathWorks ships and documents for MEX use
 * (-lmwblas -lmwlapack). It calls public BLAS/LAPACK entry points with chosen inputs and
 * returns their outputs. It reads no Rust forecast and no earlier MATLAB numerical output.
 *
 * Summation trees are read with FPRev masks: every leaf is 1.0 except one +2^80 and one
 * -2^80; the result is n minus the size of the lowest common subtree of the two marked
 * leaves. Counts are kept as 16-bit integers (the V1320 gateway clamped at 250 leaves).
 *
 * Usage from MATLAB: out = kp1351(cmd, args...)
 */
#include "mex.h"
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef ptrdiff_t I;

extern void dgemm_(const char *, const char *, const I *, const I *, const I *, const double *,
                   const double *, const I *, const double *, const I *, const double *, double *, const I *);
extern void dtrmm_(const char *, const char *, const char *, const char *, const I *, const I *,
                   const double *, const double *, const I *, double *, const I *);
extern void dcopy_(const I *, const double *, const I *, double *, const I *);
extern void dgeqp3_(const I *, const I *, double *, const I *, I *, double *, double *, const I *, I *);
extern void dormqr_(const char *, const char *, const I *, const I *, const I *, const double *,
                    const I *, const double *, double *, const I *, double *, const I *, I *);
extern void dlarfb_(const char *, const char *, const char *, const char *, const I *, const I *,
                    const I *, const double *, const I *, const double *, const I *, double *,
                    const I *, double *, const I *);
extern void dlarft_(const char *, const char *, const I *, const I *, const double *, const I *,
                    const double *, double *, const I *);
extern void dtrtrs_(const char *, const char *, const char *, const I *, const I *, const double *,
                    const I *, double *, const I *, I *);

static const I ONE = 1;
static const double D1 = 1.0, DM1 = -1.0;
/* 2^80: its ulp (2^28) dwarfs any partial sum of ones, so the marks absorb them exactly even
 * with 2,000 leaves (2^62, used by V1320 up to 250 leaves, has ulp 1,024). */
#define BIGM 1208925819614629174706176.0 /* 2^80 */

typedef struct { void *base; double *p; } Buf;
static Buf balloc(size_t n, int off) {
    Buf b;
    if (posix_memalign(&b.base, 64, (n + 16) * sizeof(double)) != 0)
        mexErrMsgIdAndTxt("kp1351:alloc", "allocation failed");
    memset(b.base, 0, (n + 16) * sizeof(double));
    b.p = (double *)b.base + off;
    return b;
}
static void bfree(Buf b) { free(b.base); }
static int geti(const mxArray *a) { return (int)mxGetScalar(a); }
static void *xmalloc(size_t bytes) {
    void *p = calloc(bytes ? bytes : 1, 1);
    if (!p) mexErrMsgIdAndTxt("kp1351:alloc", "allocation failed");
    return p;
}
static uint16_t count16(double v) {
    if (!(v == v)) return 65535;
    double r = floor(v + 0.5);
    if (r < 0) return 65534;
    if (r > 65000) return 65533;
    return (uint16_t)r;
}

/* ---------------- growable int32 output ---------------- */
typedef struct { int32_t *d; size_t n, cap; } Vec;
static void vput(Vec *v, int32_t x) {
    if (v->n == v->cap) {
        v->cap = v->cap ? 2 * v->cap : 4096;
        int32_t *q = realloc(v->d, v->cap * sizeof(int32_t));
        if (!q) mexErrMsgIdAndTxt("kp1351:alloc", "allocation failed");
        v->d = q;
    }
    v->d[v->n++] = x;
}
static mxArray *vout(Vec *v) {
    mxArray *a = mxCreateNumericMatrix(v->n, 1, mxINT32_CLASS, mxREAL);
    if (v->n) memcpy(mxGetData(a), v->d, v->n * sizeof(int32_t));
    free(v->d); v->d = NULL; v->n = v->cap = 0;
    return a;
}

/* ---------------- tree rebuild from a full LCA-size table ----------------
 * T[a*n+b] = n - result(a,b) = size of the lowest common subtree of leaves a and b.
 * The root of a leaf set S of size s splits it into the part holding S[0] (pairs with
 * S[0] whose subtree is smaller than s) and the rest. Preorder output: -1 = internal node,
 * otherwise the leaf id. Children are ordered by their smallest leaf (canonical form).
 * Every cross pair at every split is checked against the table; disagreements are counted. */
static long build_tree(const uint16_t *T, int n, int *S, int s, int *tmp, Vec *out) {
    if (s == 1) { vput(out, S[0]); return 0; }
    int a = S[0], na = 0, nb = 0;
    for (int i = 0; i < s; i++) { int x = S[i]; if (x == a || T[(size_t)a * n + x] < s) tmp[na++] = x; }
    for (int i = 0; i < s; i++) { int x = S[i]; if (!(x == a || T[(size_t)a * n + x] < s)) tmp[na + nb++] = x; }
    long bad = 0;
    if (nb == 0) { /* not a binary split: record and stop */
        vput(out, -2); vput(out, s); for (int i = 0; i < s; i++) vput(out, S[i]);
        return 1;
    }
    memcpy(S, tmp, (size_t)s * sizeof(int));
    for (int i = 0; i < na; i++) for (int j = na; j < s; j++) if (T[(size_t)S[i] * n + S[j]] != s) bad++;
    vput(out, -1);
    bad += build_tree(T, n, S, na, tmp, out);
    bad += build_tree(T, n, S + na, nb, tmp, out);
    return bad;
}

/* dedup of int32 sequences */
typedef struct { Vec all; size_t *off; int32_t *len; uint64_t *h; size_t cnt, cap; } Uniq;
static uint64_t hseq(const int32_t *d, size_t n) {
    uint64_t h = 1469598103934665603ULL ^ (uint64_t)n;
    for (size_t i = 0; i < n; i++) { h ^= (uint32_t)d[i]; h *= 1099511628211ULL; }
    return h;
}
static int32_t uadd(Uniq *u, const int32_t *d, size_t n) {
    uint64_t h = hseq(d, n);
    for (size_t i = 0; i < u->cnt; i++)
        if (u->h[i] == h && (size_t)u->len[i] == n && !memcmp(u->all.d + u->off[i], d, n * sizeof(int32_t))) return (int32_t)i;
    if (u->cnt == u->cap) {
        u->cap = u->cap ? 2 * u->cap : 64;
        u->off = realloc(u->off, u->cap * sizeof(size_t)); u->len = realloc(u->len, u->cap * sizeof(int32_t));
        u->h = realloc(u->h, u->cap * sizeof(uint64_t));
        if (!u->off || !u->len || !u->h) mexErrMsgIdAndTxt("kp1351:alloc", "allocation failed");
    }
    u->off[u->cnt] = u->all.n; u->len[u->cnt] = (int32_t)n; u->h[u->cnt] = h;
    for (size_t i = 0; i < n; i++) vput(&u->all, d[i]);
    return (int32_t)u->cnt++;
}
/* output: [nuniq, (len, data...)*, nout, ids..., extra] */
static mxArray *uemit(Uniq *u, const int32_t *ids, int nout, long extra) {
    Vec o = {0};
    vput(&o, (int32_t)u->cnt);
    for (size_t i = 0; i < u->cnt; i++) { vput(&o, u->len[i]); for (int32_t j = 0; j < u->len[i]; j++) vput(&o, u->all.d[u->off[i] + j]); }
    vput(&o, nout);
    for (int i = 0; i < nout; i++) vput(&o, ids[i]);
    vput(&o, (int32_t)(extra > 2000000000L ? 2000000000L : extra));
    free(u->all.d); free(u->off); free(u->len); free(u->h);
    return vout(&o);
}

/* ---------------- FPRev drivers ----------------
 * TN: W(w-by-k, ld w) += C2'(L-by-w, ld ldc, offset offc) * V2(L-by-k, ld ldv, offset offv).
 *     leaves: rows 0..L-1, init W = leaf L.
 * NT: C2(L-by-w, ld ldc) -= V2(L-by-k, ld ldv) * W(w-by-k)'. leaves: j = 0..k-1, init = leaf k.
 * `set_pair` writes the marks for leaves a (+) and b (-) and `run` calls dgemm and reads counts. */
typedef struct {
    int op, w, k, L, ldc, ldv, offc, offv, n, nout;
    Buf c2, v2, W;
} G;
static void g_init(G *g) {
    g->c2 = balloc((size_t)g->ldc * (size_t)(g->w > 0 ? g->w : 1) + 8, g->offc);
    g->v2 = balloc((size_t)g->ldv * (size_t)g->k + 8, g->offv);
    g->W = balloc((size_t)g->w * (size_t)g->k + 8, 0);
    g->n = (g->op == 0) ? g->L + 1 : g->k + 1;
    g->nout = (g->op == 0) ? g->w * g->k : g->L * g->w;
}
static void g_free(G *g) { bfree(g->c2); bfree(g->v2); bfree(g->W); }
/* compute counts for marks (a,b), a<b, into cnt[nout] */
static void g_run(G *g, int a, int b, uint16_t *cnt) {
    int w = g->w, k = g->k, L = g->L;
    I wi = w, ki = k, Li = L, ldc = g->ldc, ldv = g->ldv;
    double *c2 = g->c2.p, *v2 = g->v2.p, *W = g->W.p;
    if (g->op == 0) {
        for (int q = 0; q < w; q++) for (int r = 0; r < L; r++) c2[r + (size_t)q * ldc] = 1.0;
        for (int j = 0; j < k; j++) for (int r = 0; r < L; r++) v2[r + (size_t)j * ldv] = 1.0;
        for (int i = 0; i < w * k; i++) W[i] = 1.0;
        for (int q = 0; q < w; q++) c2[a + (size_t)q * ldc] = BIGM;
        if (b < L) for (int q = 0; q < w; q++) c2[b + (size_t)q * ldc] = -BIGM;
        else for (int i = 0; i < w * k; i++) W[i] = -BIGM;
        dgemm_("T", "N", &wi, &ki, &Li, &D1, c2, &ldc, v2, &ldv, &D1, W, &wi);
        for (int o = 0; o < w * k; o++) cnt[o] = count16(W[o]);
    } else {
        for (int j = 0; j < k; j++) for (int r = 0; r < L; r++) v2[r + (size_t)j * ldv] = 1.0;
        for (int i = 0; i < w * k; i++) W[i] = 1.0;
        for (int q = 0; q < w; q++) for (int r = 0; r < L; r++) c2[r + (size_t)q * ldc] = -1.0;
        for (int q = 0; q < w; q++) W[q + (size_t)a * w] = -BIGM;
        if (b < k) for (int q = 0; q < w; q++) W[q + (size_t)b * w] = BIGM;
        else for (int q = 0; q < w; q++) for (int r = 0; r < L; r++) c2[r + (size_t)q * ldc] = -BIGM;
        dgemm_("N", "T", &Li, &wi, &ki, &DM1, v2, &ldv, W, &wi, &D1, c2, &ldc);
        for (int q = 0; q < w; q++) for (int r = 0; r < L; r++) cnt[r + (size_t)q * L] = count16(-c2[r + (size_t)q * ldc]);
    }
}
static void g_parse(G *g, const mxArray *const *prhs) {
    g->op = geti(prhs[1]); g->w = geti(prhs[2]); g->k = geti(prhs[3]); g->L = geti(prhs[4]);
    g->ldc = geti(prhs[5]); g->ldv = geti(prhs[6]); g->offc = geti(prhs[7]); g->offv = geti(prhs[8]);
    if (g->ldc < g->L || g->ldv < g->L || g->offc < 0 || g->offc > 7 || g->offv < 0 || g->offv > 7 || g->w < 1 || g->k < 1 || g->L < 1)
        mexErrMsgIdAndTxt("kp1351:args", "bad shape");
}

/* ---------------- reference dlarfb over the public BLAS (as in V1320) ---------------- */
static void ref_larfb(I m, I w, I k, const double *v, I ldv, const double *t, I ldt, double *c, I ldc,
                      double *work, I ldw) {
    for (I j = 0; j < k; j++) dcopy_(&w, &c[j], &ldc, &work[j * ldw], &ONE);
    dtrmm_("R", "L", "N", "U", &w, &k, &D1, v, &ldv, work, &ldw);
    I mk = m - k;
    if (mk > 0) dgemm_("T", "N", &w, &k, &mk, &D1, &c[k], &ldc, &v[k], &ldv, &D1, work, &ldw);
    dtrmm_("R", "U", "N", "N", &w, &k, &D1, t, &ldt, work, &ldw);
    if (mk > 0) dgemm_("N", "T", &mk, &w, &k, &DM1, &v[k], &ldv, work, &ldw, &D1, &c[k], &ldc);
    dtrmm_("R", "L", "T", "U", &w, &k, &D1, v, &ldv, work, &ldw);
    for (I j = 0; j < k; j++) for (I i = 0; i < w; i++) c[j + i * ldc] -= work[i + j * ldw];
}
static void apply_blocked(int akind, I nb, I m, I w, I k, double *v, I ldv, const double *tau, double *c, I ldc) {
    Buf t = balloc((size_t)(nb * nb) + 64, 0), work = balloc((size_t)(w * nb) + 4096, 0);
    for (I i0 = 0; i0 < k; i0 += nb) {
        I ib = (k - i0 < nb) ? k - i0 : nb, mm = m - i0;
        double *vb = &v[i0 + i0 * ldv];
        memset(t.p, 0, (size_t)(nb * nb) * 8);
        dlarft_("F", "C", &mm, &ib, vb, &ldv, &tau[i0], t.p, &ib);
        if (akind == 0) dlarfb_("L", "T", "F", "C", &mm, &w, &ib, vb, &ldv, t.p, &ib, &c[i0], &ldc, work.p, &w);
        else ref_larfb(mm, w, ib, vb, ldv, t.p, ib, &c[i0], ldc, work.p, w);
    }
    bfree(t); bfree(work);
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    char cmd[32];
    (void)nlhs;
    if (nrhs < 1 || mxGetString(prhs[0], cmd, sizeof cmd))
        mexErrMsgIdAndTxt("kp1351:cmd", "first argument must be a command string");

    if (!strcmp(cmd, "tree")) {
        /* (op,w,k,L,ldc,ldv,offc,offv) -> [nuniq,(len,preorder)*,nout,ids,bad] full FPRev */
        G g; g_parse(&g, prhs); g_init(&g);
        int n = g.n, nout = g.nout;
        if ((double)nout * n * n > 1.2e8) mexErrMsgIdAndTxt("kp1351:size", "table too large");
        uint16_t *tab = xmalloc((size_t)nout * n * n * sizeof(uint16_t)), *cnt = xmalloc((size_t)nout * sizeof(uint16_t));
        for (int a = 0; a < n; a++)
            for (int b = a + 1; b < n; b++) {
                g_run(&g, a, b, cnt);
                for (int o = 0; o < nout; o++) {
                    uint16_t s = (uint16_t)(n - cnt[o] < 0 ? 0 : n - cnt[o]);
                    if (cnt[o] > n) s = 0;
                    tab[(size_t)o * n * n + (size_t)a * n + b] = s; tab[(size_t)o * n * n + (size_t)b * n + a] = s;
                }
            }
        int *S = xmalloc((size_t)n * sizeof(int)), *tmp = xmalloc((size_t)n * sizeof(int));
        int32_t *ids = xmalloc((size_t)nout * sizeof(int32_t));
        Uniq u = {0}; Vec one = {0}; long bad = 0;
        for (int o = 0; o < nout; o++) {
            for (int i = 0; i < n; i++) S[i] = i;
            one.n = 0;
            bad += build_tree(tab + (size_t)o * n * n, n, S, n, tmp, &one);
            ids[o] = uadd(&u, one.d, one.n);
        }
        plhs[0] = uemit(&u, ids, nout, bad);
        free(one.d); free(S); free(tmp); free(ids); free(tab); free(cnt); g_free(&g);
    } else if (!strcmp(cmd, "anchor")) {
        /* (op,w,k,L,ldc,ldv,offc,offv,anchors) -> per output the rows T(a,:) for each anchor a,
         * dedup across outputs: [nuniq,(len,rows)*,nout,ids,0]. T(a,a) = 0. */
        G g; g_parse(&g, prhs); g_init(&g);
        int n = g.n, nout = g.nout, na = (int)mxGetNumberOfElements(prhs[9]);
        const double *an = mxGetDoubles(prhs[9]);
        if ((double)nout * na * n > 3.0e8) mexErrMsgIdAndTxt("kp1351:size", "rows too large");
        int32_t *rows = xmalloc((size_t)nout * na * n * sizeof(int32_t));
        uint16_t *cnt = xmalloc((size_t)nout * sizeof(uint16_t));
        for (int ai = 0; ai < na; ai++) {
            int a = (int)an[ai];
            if (a < 0 || a >= n) mexErrMsgIdAndTxt("kp1351:args", "bad anchor");
            for (int b = 0; b < n; b++) {
                if (b == a) { for (int o = 0; o < nout; o++) rows[((size_t)o * na + ai) * n + b] = 0; continue; }
                g_run(&g, a < b ? a : b, a < b ? b : a, cnt);
                for (int o = 0; o < nout; o++) rows[((size_t)o * na + ai) * n + b] = n - (int32_t)cnt[o];
            }
        }
        int32_t *ids = xmalloc((size_t)nout * sizeof(int32_t));
        Uniq u = {0};
        for (int o = 0; o < nout; o++) ids[o] = uadd(&u, rows + (size_t)o * na * n, (size_t)na * n);
        plhs[0] = uemit(&u, ids, nout, 0);
        free(rows); free(cnt); free(ids); g_free(&g);
    } else if (!strcmp(cmd, "gemmx")) {
        /* (ta,tb,M,N,K,alpha,beta,A,offA,B,offB,C,offC): A,B,C passed as full ld arrays (ld = rows)
         * and copied to buffers `off` doubles past 64-byte alignment. Returns C. */
        char ta[4], tb[4];
        mxGetString(prhs[1], ta, sizeof ta); mxGetString(prhs[2], tb, sizeof tb);
        I M = geti(prhs[3]), N = geti(prhs[4]), K = geti(prhs[5]);
        double alpha = mxGetScalar(prhs[6]), beta = mxGetScalar(prhs[7]);
        I lda = (I)mxGetM(prhs[8]), ldb = (I)mxGetM(prhs[10]), ldc = (I)mxGetM(prhs[12]);
        size_t na = mxGetNumberOfElements(prhs[8]), nb = mxGetNumberOfElements(prhs[10]), nc = mxGetNumberOfElements(prhs[12]);
        Buf A = balloc(na, geti(prhs[9])), B = balloc(nb, geti(prhs[11])), C = balloc(nc, geti(prhs[13]));
        memcpy(A.p, mxGetDoubles(prhs[8]), na * 8); memcpy(B.p, mxGetDoubles(prhs[10]), nb * 8);
        memcpy(C.p, mxGetDoubles(prhs[12]), nc * 8);
        dgemm_(ta, tb, &M, &N, &K, &alpha, A.p, &lda, B.p, &ldb, &beta, C.p, &ldc);
        plhs[0] = mxCreateDoubleMatrix(mxGetM(prhs[12]), mxGetN(prhs[12]), mxREAL);
        memcpy(mxGetDoubles(plhs[0]), C.p, nc * 8);
        bfree(A); bfree(B); bfree(C);
    } else if (!strcmp(cmd, "chain")) {
        /* (X m-by-n, B m-by-w) -> [Z (n-by-w) from dgeqp3 -> dormqr('L','T') -> dtrtrs (full rank);
         *  then Q'B by dormqr, by blocked MKL dlarft+dlarfb (nb 8), by blocked ref over public dgemm,
         *  each m-by-w, stacked as columns] */
        I m = (I)mxGetM(prhs[1]), n = (I)mxGetN(prhs[1]), w = (I)mxGetN(prhs[2]), info = 0, lw = -1;
        if ((I)mxGetM(prhs[2]) != m || n > m) mexErrMsgIdAndTxt("kp1351:args", "shape");
        double *A = xmalloc((size_t)(m * n) * 8), *tau = xmalloc((size_t)n * 8 + 8), q = 0;
        I *jp = xmalloc((size_t)n * sizeof(I));
        memcpy(A, mxGetDoubles(prhs[1]), (size_t)(m * n) * 8);
        dgeqp3_(&m, &n, A, &m, jp, tau, &q, &lw, &info);
        lw = (I)q; double *wk = xmalloc((size_t)(lw > 1 ? lw : 1) * 8);
        dgeqp3_(&m, &n, A, &m, jp, tau, wk, &lw, &info); free(wk);
        plhs[0] = mxCreateDoubleMatrix((size_t)m, (size_t)(4 * w), mxREAL);
        double *out = mxGetDoubles(plhs[0]);
        for (int v = 0; v < 3; v++) {
            double *C = out + (size_t)(v + 1) * m * w;
            memcpy(C, mxGetDoubles(prhs[2]), (size_t)(m * w) * 8);
            if (v == 0) {
                lw = -1; dormqr_("L", "T", &m, &w, &n, A, &m, tau, C, &m, &q, &lw, &info);
                lw = (I)q; wk = xmalloc((size_t)(lw > 1 ? lw : 1) * 8);
                dormqr_("L", "T", &m, &w, &n, A, &m, tau, C, &m, wk, &lw, &info); free(wk);
            } else {
                apply_blocked(v == 1 ? 0 : 1, 8, m, w, n, A, m, tau, C, m);
            }
        }
        double *Z = out; /* first block: solution in rows 0..n-1, permuted back */
        double *Cq = xmalloc((size_t)(m * w) * 8);
        memcpy(Cq, out + (size_t)m * w, (size_t)(m * w) * 8);
        dtrtrs_("U", "N", "N", &n, &w, A, &m, Cq, &m, &info);
        for (I j = 0; j < w; j++) for (I i = 0; i < m; i++) Z[i + j * m] = 0.0;
        for (I j = 0; j < w; j++) for (I i = 0; i < n; i++) Z[(jp[i] - 1) + j * m] = Cq[i + j * m];
        free(Cq); free(A); free(tau); free(jp);
    } else {
        mexErrMsgIdAndTxt("kp1351:cmd", "unknown command");
    }
}
