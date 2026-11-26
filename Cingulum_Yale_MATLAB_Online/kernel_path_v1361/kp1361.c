/* kp1361.c — V1361 original-only dtrmm summation-tree probe with a strided workspace.
 *
 * A plain MEX gateway onto the BLAS that MathWorks ships and documents for MEX use
 * (-lmwblas). Copied from kp1359.c (V1359) with one change: 'trmmtree' takes an optional
 * leading dimension ldb >= m for W (default m), so the trees of dtrmm on a one-row workspace
 * whose leading dimension is the whole width (dlarfb's last one-column panel) can be read.
 * It reads no Rust forecast and no earlier MATLAB numerical output.
 *
 *   p = kp1361('trmmtree', uplo, trans, diag, m, n[, ldb])
 *       dtrmm('R', uplo, trans, diag, m, n, 1, M, n, W, ldb) with every entry of M equal to 1;
 *       output format as kp1359 'trmmtree' (outputs numbered c + j*m).
 *   W = kp1361('trmmx', uplo, trans, diag, M, W): as kp1359.
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
        mexErrMsgIdAndTxt("kp1361:alloc", "allocation failed");
    memset(b.base, 0, (n + 16) * sizeof(double));
    b.p = (double *)b.base + off;
    return b;
}
static void bfree(Buf b) { free(b.base); }
static int geti(const mxArray *a) { return (int)mxGetScalar(a); }
static void *xmalloc(size_t bytes) {
    void *p = calloc(bytes ? bytes : 1, 1);
    if (!p) mexErrMsgIdAndTxt("kp1361:alloc", "allocation failed");
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
        if (!q) mexErrMsgIdAndTxt("kp1361:alloc", "allocation failed");
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
        if (!u->off || !u->len || !u->h) mexErrMsgIdAndTxt("kp1361:alloc", "allocation failed");
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

static int in_support(char uplo, char trans, int l, int j) {
    if (uplo == 'L' && trans == 'N') return l >= j;
    return l <= j; /* 'U','N' and 'L','T' */
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    char cmd[32], uplo[4], trans[4], diag[4];
    (void)nlhs;
    if (nrhs < 4 || mxGetString(prhs[0], cmd, sizeof cmd) || mxGetString(prhs[1], uplo, sizeof uplo) ||
        mxGetString(prhs[2], trans, sizeof trans) || mxGetString(prhs[3], diag, sizeof diag))
        mexErrMsgIdAndTxt("kp1361:cmd", "command, uplo, trans, diag");
    if (!strcmp(cmd, "trmmtree")) {
        int m = geti(prhs[4]), n = geti(prhs[5]);
        int ld = nrhs > 6 ? geti(prhs[6]) : m;
        if (m < 1 || n < 1 || n > 64 || ld < m) mexErrMsgIdAndTxt("kp1361:args", "bad shape");
        I mi = m, ni = n, ldi = ld;
        int nout = m * n;
        uint16_t *tab = xmalloc((size_t)nout * n * n * sizeof(uint16_t));
        Buf M = balloc((size_t)n * n, 0), W = balloc((size_t)ld * n, 0);
        for (int a = 0; a < n; a++)
            for (int b = a + 1; b < n; b++) {
                for (int i = 0; i < n * n; i++) M.p[i] = 1.0;
                for (int i = 0; i < ld * n; i++) W.p[i] = 1.0;
                for (int c = 0; c < m; c++) { W.p[c + (size_t)a * ld] = BIGM; W.p[c + (size_t)b * ld] = -BIGM; }
                dtrmm_("R", uplo, trans, diag, &mi, &ni, &D1, M.p, &ni, W.p, &ldi);
                for (int j = 0; j < n; j++) {
                    if (!in_support(uplo[0], trans[0], a, j) || !in_support(uplo[0], trans[0], b, j)) continue;
                    int s = 0;
                    for (int l = 0; l < n; l++) s += in_support(uplo[0], trans[0], l, j);
                    for (int c = 0; c < m; c++) {
                        uint16_t r = count16(W.p[c + (size_t)j * ld]);
                        uint16_t lca = (uint16_t)(r > s ? 0 : s - r);
                        size_t o = (size_t)(c + j * m);
                        tab[o * n * n + (size_t)a * n + b] = lca; tab[o * n * n + (size_t)b * n + a] = lca;
                    }
                }
            }
        int *S = xmalloc((size_t)n * sizeof(int)), *tmp = xmalloc((size_t)n * sizeof(int));
        int32_t *ids = xmalloc((size_t)nout * sizeof(int32_t));
        Uniq u = {0}; Vec one = {0}; long bad = 0;
        for (int o = 0; o < nout; o++) {
            int j = o / m, s = 0;
            for (int l = 0; l < n; l++) if (in_support(uplo[0], trans[0], l, j)) S[s++] = l;
            one.n = 0;
            bad += build_tree(tab + (size_t)o * n * n, n, S, s, tmp, &one);
            ids[o] = uadd(&u, one.d, one.n);
        }
        plhs[0] = uemit(&u, ids, nout, bad);
        free(one.d); free(S); free(tmp); free(ids); free(tab); bfree(M); bfree(W);
    } else if (!strcmp(cmd, "trmmx")) {
        I n = (I)mxGetM(prhs[4]), m = (I)mxGetM(prhs[5]);
        if ((I)mxGetN(prhs[4]) != n || (I)mxGetN(prhs[5]) != n) mexErrMsgIdAndTxt("kp1361:args", "shapes");
        Buf M = balloc((size_t)(n * n), 0), W = balloc((size_t)(m * n), 0);
        memcpy(M.p, mxGetDoubles(prhs[4]), (size_t)(n * n) * 8); memcpy(W.p, mxGetDoubles(prhs[5]), (size_t)(m * n) * 8);
        dtrmm_("R", uplo, trans, diag, &m, &n, &D1, M.p, &n, W.p, &m);
        plhs[0] = mxCreateDoubleMatrix((size_t)m, (size_t)n, mxREAL);
        memcpy(mxGetDoubles(plhs[0]), W.p, (size_t)(m * n) * 8);
        bfree(M); bfree(W);
    } else {
        mexErrMsgIdAndTxt("kp1361:cmd", "unknown command");
    }
}
