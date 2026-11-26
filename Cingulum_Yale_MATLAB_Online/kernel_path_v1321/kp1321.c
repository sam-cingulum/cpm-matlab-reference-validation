/* kp1321.c — V1321 original-only robustfit triangular-solve and small-product probe.
 *
 * A plain MEX gateway onto the BLAS/LAPACK that MathWorks ships and documents
 * for MEX use (-lmwblas -lmwlapack). It only calls public BLAS/LAPACK entry
 * points with chosen inputs and returns their outputs. It reads no Rust
 * forecast and no earlier MATLAB numerical output.
 *
 * Usage from MATLAB: out = kp1321(cmd, args...)
 */
#include "mex.h"
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef ptrdiff_t I;

extern double ddot_(const I *, const double *, const I *, const double *, const I *);
extern double dnrm2_(const I *, const double *, const I *);
extern void daxpy_(const I *, const double *, const double *, const I *, double *, const I *);
extern void dscal_(const I *, const double *, double *, const I *);
extern void dgemv_(const char *, const I *, const I *, const double *, const double *, const I *,
                   const double *, const I *, const double *, double *, const I *);
extern void dger_(const I *, const I *, const double *, const double *, const I *, const double *,
                  const I *, double *, const I *);
extern void dtrsm_(const char *, const char *, const char *, const char *, const I *, const I *,
                   const double *, const double *, const I *, double *, const I *);
extern void dtrsv_(const char *, const char *, const char *, const I *, const double *, const I *,
                   double *, const I *);
extern void dgeqp3_(const I *, const I *, double *, const I *, I *, double *, double *, const I *, I *);
extern void dgeqrf_(const I *, const I *, double *, const I *, double *, double *, const I *, I *);
extern void dgeqr2_(const I *, const I *, double *, const I *, double *, double *, I *);
extern void dormqr_(const char *, const char *, const I *, const I *, const I *, const double *,
                    const I *, const double *, double *, const I *, double *, const I *, I *);
extern void dorm2r_(const char *, const char *, const I *, const I *, const I *, const double *,
                    const I *, const double *, double *, const I *, double *, I *);
extern void dlarf_(const char *, const I *, const I *, const double *, const I *, const double *,
                   double *, const I *, double *);
extern void dlarfg_(const I *, double *, double *, const I *, double *);
extern void dlarfb_(const char *, const char *, const char *, const char *, const I *, const I *,
                    const I *, const double *, const I *, const double *, const I *, double *,
                    const I *, double *, const I *);
extern void dlarft_(const char *, const char *, const I *, const I *, const double *, const I *,
                    const double *, double *, const I *);
extern void dtrtrs_(const char *, const char *, const char *, const I *, const I *, const double *,
                    const I *, double *, const I *, I *);
extern void dgels_(const char *, const I *, const I *, const I *, double *, const I *, double *,
                   const I *, double *, const I *, I *);
extern void dgelsy_(const I *, const I *, const I *, double *, const I *, double *, const I *, I *,
                    const double *, I *, double *, const I *, I *);

extern void dgemm_(const char *, const char *, const I *, const I *, const I *, const double *,
                   const double *, const I *, const double *, const I *, const double *, double *, const I *);
extern void dtrmm_(const char *, const char *, const char *, const char *, const I *, const I *,
                   const double *, const double *, const I *, double *, const I *);
extern void dtrmv_(const char *, const char *, const char *, const I *, const double *, const I *,
                   double *, const I *);
extern void dcopy_(const I *, const double *, const I *, double *, const I *);
extern void dorgqr_(const I *, const I *, const I *, double *, const I *, const double *, double *,
                    const I *, I *);
extern void dorg2r_(const I *, const I *, const I *, double *, const I *, const double *, double *, I *);
extern void dsyrk_(const char *, const char *, const I *, const I *, const double *, const double *,
                   const I *, const double *, double *, const I *);
extern void dtrtri_(const char *, const char *, const I *, double *, const I *, I *);

static const I ONE = 1;
static const double D1 = 1.0, D0 = 0.0;

/* 64-byte aligned buffer of n doubles starting `off` doubles past alignment. */
typedef struct { void *base; double *p; } Buf;
static Buf balloc(size_t n, int off) {
    Buf b;
    if (posix_memalign(&b.base, 64, (n + 16) * sizeof(double)) != 0)
        mexErrMsgIdAndTxt("kp1321:alloc", "allocation failed");
    memset(b.base, 0, (n + 16) * sizeof(double));
    b.p = (double *)b.base + off;
    return b;
}
static void bfree(Buf b) { free(b.base); }


static const double DM1 = -1.0;
#define BIGM 4611686018427387904.0 /* 2^62 */

/* ---------------- unique-tree registry and index stream (kept across calls) ---------------- */
static uint8_t *u_data = NULL; static size_t u_len = 0, u_cap = 0;
static uint64_t *u_hash = NULL; static int32_t *u_n = NULL; static size_t *u_off = NULL;
static size_t u_count = 0, u_capn = 0;
static int32_t *h_tab = NULL; static size_t h_cap = 0;
static int32_t *x_data = NULL; static size_t x_len = 0, x_cap = 0;

static void *xgrow(void *p, size_t bytes) {
    void *q = realloc(p, bytes);
    if (!q) mexErrMsgIdAndTxt("kp1321:alloc", "registry allocation failed");
    return q;
}
static void idx_put(int32_t v) {
    if (x_len == x_cap) { x_cap = x_cap ? 2 * x_cap : (1u << 20); x_data = xgrow(x_data, x_cap * sizeof(int32_t)); }
    x_data[x_len++] = v;
}
static int32_t reg(const uint8_t *L, int n) {
    size_t bytes = (size_t)n * (size_t)n;
    uint64_t h = 1469598103934665603ULL ^ (uint64_t)n;
    for (size_t i = 0; i < bytes; i++) { h ^= L[i]; h *= 1099511628211ULL; }
    if (!h_tab) { h_cap = (size_t)1 << 22; h_tab = xgrow(NULL, h_cap * sizeof(int32_t)); memset(h_tab, 0, h_cap * sizeof(int32_t)); }
    size_t slot = (size_t)(h & (h_cap - 1));
    while (h_tab[slot]) {
        int32_t id = h_tab[slot];
        if (u_hash[id - 1] == h && u_n[id - 1] == n && !memcmp(u_data + u_off[id - 1], L, bytes)) return id;
        slot = (slot + 1) & (h_cap - 1);
    }
    if (u_count == u_capn) {
        u_capn = u_capn ? 2 * u_capn : 4096;
        u_hash = xgrow(u_hash, u_capn * sizeof(uint64_t)); u_n = xgrow(u_n, u_capn * sizeof(int32_t));
        u_off = xgrow(u_off, u_capn * sizeof(size_t));
    }
    if (u_len + bytes > u_cap) { while (u_len + bytes > u_cap) u_cap = u_cap ? 2 * u_cap : (1u << 22); u_data = xgrow(u_data, u_cap); }
    memcpy(u_data + u_len, L, bytes);
    u_hash[u_count] = h; u_n[u_count] = n; u_off[u_count] = u_len; u_len += bytes; u_count++;
    if (u_count * 2 > h_cap) mexErrMsgIdAndTxt("kp1321:reg", "registry full");
    h_tab[slot] = (int32_t)u_count;
    return (int32_t)u_count;
}
static uint8_t clampcount(double v) {
    if (!(v == v)) return 255;
    double r = floor(v + 0.5);
    if (r < 0) return 254;
    if (r > 250) return 253;
    return (uint8_t)r;
}
/* tab: nout blocks of n*n bytes; register leaf sub-range [lo,hi) of each output and write ids */
static void reg_outputs(const uint8_t *tab, int n, int nout, const int *lo, const int *hi, uint8_t *scratch) {
    for (int o = 0; o < nout; o++) {
        int a0 = lo ? lo[o] : 0, a1 = hi ? hi[o] : n, s = a1 - a0;
        if (s <= 0) { idx_put(0); continue; }
        const uint8_t *T = tab + (size_t)o * n * n;
        for (int a = 0; a < s; a++) for (int b = 0; b < s; b++) scratch[a * s + b] = (a == b) ? 0 : T[(a0 + a) * n + (a0 + b)];
        idx_put(reg(scratch, s));
    }
}

/* ---------------- reference dlarft / dlarfb over the public BLAS ---------------- */
static void ref_larft_nonrec(I n, I k, const double *v, I ldv, const double *tau, double *t, I ldt) {
    I prevlastv = n;
    for (I i = 0; i < k; i++) {
        if (prevlastv < i + 1) prevlastv = i + 1;
        if (tau[i] == 0.0) { for (I j = 0; j <= i; j++) t[j + i * ldt] = 0.0; continue; }
        I lastv = n;
        while (lastv > i + 1 && v[(lastv - 1) + i * ldv] == 0.0) lastv--;
        for (I j = 0; j < i; j++) t[j + i * ldt] = -tau[i] * v[i + j * ldv];
        I jj = lastv < prevlastv ? lastv : prevlastv;
        I rows = jj - (i + 1), cols = i;
        double mt = -tau[i];
        if (rows > 0 && cols > 0)
            dgemv_("T", &rows, &cols, &mt, &v[(i + 1)], &ldv, &v[(i + 1) + i * ldv], &ONE, &D1, &t[i * ldt], &ONE);
        if (cols > 0) dtrmv_("U", "N", "N", &cols, t, &ldt, &t[i * ldt], &ONE);
        t[i + i * ldt] = tau[i];
        if (i > 0) { if (lastv > prevlastv) prevlastv = lastv; } else prevlastv = lastv;
    }
}
static void ref_larft_rec(I n, I k, const double *v, I ldv, const double *tau, double *t, I ldt) {
    if (n == 0 || k == 0) return;
    if (n == 1 || k == 1) { t[0] = tau[0]; return; }
    I l = k / 2, kl = k - l, nk = n - k;
    ref_larft_rec(n, l, v, ldv, tau, t, ldt);
    ref_larft_rec(n - l, kl, &v[l + l * ldv], ldv, &tau[l], &t[l + l * ldt], ldt);
    for (I j = 0; j < l; j++) for (I i = 0; i < kl; i++) t[j + (l + i) * ldt] = v[(l + i) + j * ldv];
    dtrmm_("R", "L", "N", "U", &l, &kl, &D1, &v[l + l * ldv], &ldv, &t[l * ldt], &ldt);
    if (nk > 0)
        dgemm_("T", "N", &l, &kl, &nk, &D1, &v[k], &ldv, &v[k + l * ldv], &ldv, &D1, &t[l * ldt], &ldt);
    dtrmm_("L", "U", "N", "N", &l, &kl, &DM1, t, &ldt, &t[l * ldt], &ldt);
    dtrmm_("R", "U", "N", "N", &l, &kl, &D1, &t[l + l * ldt], &ldt, &t[l * ldt], &ldt);
}
/* C := H' C, H = I - V T V', left, forward, columnwise; work is w-by-k */
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
/* blocked application with block size nb using chosen T and apply implementations */
static void apply_blocked(int tkind, int akind, I nb, I m, I w, I k, double *v, I ldv, const double *tau,
                          double *c, I ldc) {
    Buf t = balloc((size_t)(k * k) + 64, 0), work = balloc((size_t)(w * k) + 64 * (size_t)(m + w + k) + 4096, 0);
    for (I i0 = 0; i0 < k; i0 += nb) {
        I ib = (k - i0 < nb) ? k - i0 : nb, mm = m - i0;
        double *vb = &v[i0 + i0 * ldv];
        memset(t.p, 0, (size_t)(k * k) * 8);
        if (tkind == 0) dlarft_("F", "C", &mm, &ib, vb, &ldv, &tau[i0], t.p, &ib);
        else if (tkind == 1) ref_larft_nonrec(mm, ib, vb, ldv, &tau[i0], t.p, ib);
        else ref_larft_rec(mm, ib, vb, ldv, &tau[i0], t.p, ib);
        if (akind == 0) dlarfb_("L", "T", "F", "C", &mm, &w, &ib, vb, &ldv, t.p, &ib, &c[i0], &ldc, work.p, &w);
        else ref_larfb(mm, w, ib, vb, ldv, t.p, ib, &c[i0], ldc, work.p, w);
    }
    bfree(t); bfree(work);
}

/* netlib-structured blocked dorgqr (nx = 0) over MKL's own dorg2r/dlarft/dlarfb */
static void ref_orgqr_blk(I m, I n, I k, I nb, double *a, I lda, const double *tau) {
    I info = 0, ki = 0, kk = 0;
    Buf t = balloc((size_t)(nb * nb) + 64, 0), work = balloc((size_t)(n * nb) + 64 * (size_t)(m + n) + 4096, 0);
    if (nb >= 2 && nb < k) {
        ki = ((k - 1) / nb) * nb;
        kk = (k < ki + nb) ? k : ki + nb;
        for (I j = kk; j < n; j++) for (I i = 0; i < kk; i++) a[i + j * lda] = 0.0;
    }
    if (kk < n) {
        I mm = m - kk, nn = n - kk, k2 = k - kk;
        dorg2r_(&mm, &nn, &k2, &a[kk + kk * lda], &lda, &tau[kk], work.p, &info);
    }
    if (kk > 0) {
        for (I i = ki; i >= 0; i -= nb) {
            I ib = (nb < k - i) ? nb : k - i, mm = m - i;
            if (i + ib < n) {
                I nn = n - i - ib;
                dlarft_("F", "C", &mm, &ib, &a[i + i * lda], &lda, &tau[i], t.p, &ib);
                dlarfb_("L", "N", "F", "C", &mm, &nn, &ib, &a[i + i * lda], &lda, t.p, &ib,
                        &a[i + (i + ib) * lda], &lda, work.p, &nn);
            }
            dorg2r_(&mm, &ib, &ib, &a[i + i * lda], &lda, &tau[i], work.p, &info);
            for (I j = i; j < i + ib; j++) for (I l = 0; l < i; l++) a[l + j * lda] = 0.0;
        }
    }
    bfree(t); bfree(work);
}

static int geti(const mxArray *a) { return (int)mxGetScalar(a); }
static mxArray *mkmat(size_t m, size_t n) { return mxCreateDoubleMatrix(m, n, mxREAL); }

/* ---- reference (netlib-order) Householder pieces built on the BLAS kernels ---- */
static double ref_lapy2(double x, double y) {
    double xa = fabs(x), ya = fabs(y);
    double w = xa > ya ? xa : ya, z = xa > ya ? ya : xa;
    if (z == 0.0) return w;
    double q = z / w;
    return w * sqrt(1.0 + q * q);
}
static void ref_larfg(I n, double *alpha, double *x, double *tau) {
    if (n <= 1) { *tau = 0.0; return; }
    I nm1 = n - 1;
    double xnorm = dnrm2_(&nm1, x, &ONE);
    if (xnorm == 0.0) { *tau = 0.0; return; }
    double beta = -copysign(ref_lapy2(*alpha, xnorm), *alpha);
    *tau = (beta - *alpha) / beta;
    double s = 1.0 / (*alpha - beta);
    dscal_(&nm1, &s, x, &ONE);
    *alpha = beta;
}
static void ref_larf(I m, I n, const double *v, double tau, double *c, I ldc, double *work) {
    if (tau == 0.0 || n <= 0) return;
    double mt = -tau;
    dgemv_("T", &m, &n, &D1, c, &ldc, v, &ONE, &D0, work, &ONE);
    dger_(&m, &n, &mt, v, &ONE, work, &ONE, c, &ldc);
}
static void ref_geqr2(I m, I n, double *a, I lda, double *tau, double *work) {
    I k = m < n ? m : n;
    for (I i = 0; i < k; i++) {
        I len = m - i;
        ref_larfg(len, &a[i + i * lda], &a[(i + 1 < m ? i + 1 : i) + i * lda], &tau[i]);
        if (i < n - 1) {
            double aii = a[i + i * lda];
            a[i + i * lda] = 1.0;
            ref_larf(len, n - i - 1, &a[i + i * lda], tau[i], &a[i + (i + 1) * lda], lda, work);
            a[i + i * lda] = aii;
        }
    }
}
static void ref_orm2r(I m, I w, I k, double *a, I lda, const double *tau, double *c, I ldc,
                      double *work) {
    for (I i = 0; i < k; i++) {
        double aii = a[i + i * lda];
        a[i + i * lda] = 1.0;
        ref_larf(m - i, w, &a[i + i * lda], tau[i], &c[i], ldc, work);
        a[i + i * lda] = aii;
    }
}

/* solve min ||A x - B|| by the named routine sequence; returns p-by-w */
static void solve(int method, int off, I n, I p, I w, const double *A0, const double *B0,
                  double *X, double *info_out) {
    I lda = n, ldb = n, info = 0, lwork = 64 * (n + p + w) + 4096;
    Buf a = balloc((size_t)(n * p), off), b = balloc((size_t)(n * w), off);
    Buf tau = balloc((size_t)p, 0), work = balloc((size_t)lwork, 0);
    I *jpvt = (I *)calloc((size_t)p, sizeof(I));
    memcpy(a.p, A0, (size_t)(n * p) * sizeof(double));
    memcpy(b.p, B0, (size_t)(n * w) * sizeof(double));
    int pivoted = 0;
    I rank = p;
    switch (method) {
    case 1: case 2: case 7: case 8: case 10: case 11: case 12:
        dgeqp3_(&n, &p, a.p, &lda, jpvt, tau.p, work.p, &lwork, &info);
        pivoted = 1;
        break;
    case 3:
        dgeqrf_(&n, &p, a.p, &lda, tau.p, work.p, &lwork, &info);
        break;
    case 4:
        dgeqr2_(&n, &p, a.p, &lda, tau.p, work.p, &info);
        break;
    case 9:
        ref_geqr2(n, p, a.p, lda, tau.p, work.p);
        break;
    case 5:
        dgels_("N", &n, &p, &w, a.p, &lda, b.p, &ldb, work.p, &lwork, &info);
        break;
    case 6: {
        double rcond = 2.220446049250313e-16;
        dgelsy_(&n, &p, &w, a.p, &lda, b.p, &ldb, jpvt, &rcond, &rank, work.p, &lwork, &info);
        pivoted = 2;
        break;
    }
    default:
        mexErrMsgIdAndTxt("kp1321:method", "unknown solve method");
    }
    /* apply Q' */
    switch (method) {
    case 1: case 3: case 8: case 12:
        dormqr_("L", "T", &n, &w, &p, a.p, &lda, tau.p, b.p, &ldb, work.p, &lwork, &info);
        break;
    case 2: case 4:
        dorm2r_("L", "T", &n, &w, &p, a.p, &lda, tau.p, b.p, &ldb, work.p, &info);
        break;
    case 7:
        for (I j = 0; j < w; j++)
            dormqr_("L", "T", &n, &ONE, &p, a.p, &lda, tau.p, b.p + j * ldb, &ldb, work.p, &lwork, &info);
        break;
    case 9: case 10:
        ref_orm2r(n, w, p, a.p, lda, tau.p, b.p, ldb, work.p);
        break;
    case 11: {
        Buf t = balloc((size_t)(p * p), 0);
        dlarft_("F", "C", &n, &p, a.p, &lda, tau.p, t.p, &p);
        dlarfb_("L", "T", "F", "C", &n, &w, &p, a.p, &lda, t.p, &p, b.p, &ldb, work.p, &w);
        bfree(t);
        break;
    }
    default: break;
    }
    /* triangular solve */
    switch (method) {
    case 1: case 2: case 3: case 4: case 11:
        dtrtrs_("U", "N", "N", &p, &w, a.p, &lda, b.p, &ldb, &info);
        break;
    case 7:
        for (I j = 0; j < w; j++)
            dtrtrs_("U", "N", "N", &p, &ONE, a.p, &lda, b.p + j * ldb, &ldb, &info);
        break;
    case 8: case 9: case 10:
        dtrsm_("L", "U", "N", "N", &p, &w, &D1, a.p, &lda, b.p, &ldb);
        break;
    case 12:
        for (I j = 0; j < w; j++)
            dtrsv_("U", "N", "N", &p, a.p, &lda, b.p + j * ldb, &ONE);
        break;
    default: break;
    }
    for (I j = 0; j < w; j++)
        for (I i = 0; i < p; i++) {
            I dst = (pivoted && jpvt[i] > 0) ? jpvt[i] - 1 : i;
            X[dst + j * p] = b.p[i + j * ldb];
        }
    *info_out = (double)info + 1000.0 * (double)(p - rank);
    free(jpvt); bfree(a); bfree(b); bfree(tau); bfree(work);
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    char cmd[32];
    if (nrhs < 1 || mxGetString(prhs[0], cmd, sizeof cmd))
        mexErrMsgIdAndTxt("kp1321:cmd", "first argument must be a command string");
    const double M = 4611686018427387904.0; /* 2^62 */

    if (!strcmp(cmd, "dot")) { /* (x,y,offx,offy) */
        I n = (I)mxGetNumberOfElements(prhs[1]);
        Buf x = balloc((size_t)n, geti(prhs[3])), y = balloc((size_t)n, geti(prhs[4]));
        memcpy(x.p, mxGetDoubles(prhs[1]), (size_t)n * 8);
        memcpy(y.p, mxGetDoubles(prhs[2]), (size_t)n * 8);
        plhs[0] = mxCreateDoubleScalar(ddot_(&n, x.p, &ONE, y.p, &ONE));
        bfree(x); bfree(y);
    } else if (!strcmp(cmd, "nrm2")) { /* (x,off) */
        I n = (I)mxGetNumberOfElements(prhs[1]);
        Buf x = balloc((size_t)n, geti(prhs[2]));
        memcpy(x.p, mxGetDoubles(prhs[1]), (size_t)n * 8);
        plhs[0] = mxCreateDoubleScalar(dnrm2_(&n, x.p, &ONE));
        bfree(x);
    } else if (!strcmp(cmd, "axpy")) { /* (a,x,y) */
        I n = (I)mxGetNumberOfElements(prhs[2]);
        double a = mxGetScalar(prhs[1]);
        plhs[0] = mxDuplicateArray(prhs[3]);
        daxpy_(&n, &a, mxGetDoubles(prhs[2]), &ONE, mxGetDoubles(plhs[0]), &ONE);
    } else if (!strcmp(cmd, "scal")) { /* (a,x) */
        I n = (I)mxGetNumberOfElements(prhs[2]);
        double a = mxGetScalar(prhs[1]);
        plhs[0] = mxDuplicateArray(prhs[2]);
        dscal_(&n, &a, mxGetDoubles(plhs[0]), &ONE);
    } else if (!strcmp(cmd, "gemv")) { /* (transflag,A,x,offA,offx,ldaextra) alpha=1,beta=0 */
        int tr = geti(prhs[1]);
        I m = (I)mxGetM(prhs[2]), n = (I)mxGetN(prhs[2]);
        int offA = geti(prhs[4]), offx = geti(prhs[5]);
        I lda = m + geti(prhs[6]);
        I nx = tr ? m : n, ny = tr ? n : m;
        Buf a = balloc((size_t)(lda * n), offA), x = balloc((size_t)nx, offx), y = balloc((size_t)ny, 0);
        const double *A = mxGetDoubles(prhs[2]);
        for (I j = 0; j < n; j++) memcpy(a.p + j * lda, A + j * m, (size_t)m * 8);
        memcpy(x.p, mxGetDoubles(prhs[3]), (size_t)nx * 8);
        dgemv_(tr ? "T" : "N", &m, &n, &D1, a.p, &lda, x.p, &ONE, &D0, y.p, &ONE);
        plhs[0] = mkmat((size_t)ny, 1);
        memcpy(mxGetDoubles(plhs[0]), y.p, (size_t)ny * 8);
        bfree(a); bfree(x); bfree(y);
    } else if (!strcmp(cmd, "ger")) { /* (alpha,x,y,A) */
        I m = (I)mxGetM(prhs[4]), n = (I)mxGetN(prhs[4]);
        double alpha = mxGetScalar(prhs[1]);
        plhs[0] = mxDuplicateArray(prhs[4]);
        dger_(&m, &n, &alpha, mxGetDoubles(prhs[2]), &ONE, mxGetDoubles(prhs[3]), &ONE,
              mxGetDoubles(plhs[0]), &m);
    } else if (!strcmp(cmd, "trsm")) { /* (R,B) left upper notrans nonunit */
        I p = (I)mxGetM(prhs[1]), w = (I)mxGetN(prhs[2]);
        plhs[0] = mxDuplicateArray(prhs[2]);
        dtrsm_("L", "U", "N", "N", &p, &w, &D1, mxGetDoubles(prhs[1]), &p, mxGetDoubles(plhs[0]), &p);
    } else if (!strcmp(cmd, "trsv")) { /* (R,B) column by column */
        I p = (I)mxGetM(prhs[1]), w = (I)mxGetN(prhs[2]);
        plhs[0] = mxDuplicateArray(prhs[2]);
        for (I j = 0; j < w; j++)
            dtrsv_("U", "N", "N", &p, mxGetDoubles(prhs[1]), &p, mxGetDoubles(plhs[0]) + j * p, &ONE);
    } else if (!strcmp(cmd, "trtrs")) { /* (R,B) */
        I p = (I)mxGetM(prhs[1]), w = (I)mxGetN(prhs[2]), info = 0;
        plhs[0] = mxDuplicateArray(prhs[2]);
        dtrtrs_("U", "N", "N", &p, &w, mxGetDoubles(prhs[1]), &p, mxGetDoubles(plhs[0]), &p, &info);
    } else if (!strcmp(cmd, "larfg")) { /* (alpha,x) -> [beta;tau;v] */
        I nm1 = (I)mxGetNumberOfElements(prhs[2]), n = nm1 + 1;
        double alpha = mxGetScalar(prhs[1]), tau = 0.0;
        plhs[0] = mkmat((size_t)(nm1 + 2), 1);
        double *o = mxGetDoubles(plhs[0]);
        memcpy(o + 2, mxGetDoubles(prhs[2]), (size_t)nm1 * 8);
        dlarfg_(&n, &alpha, o + 2, &ONE, &tau);
        o[0] = alpha; o[1] = tau;
    } else if (!strcmp(cmd, "larf")) { /* (v,tau,C,offC) left */
        I m = (I)mxGetM(prhs[3]), n = (I)mxGetN(prhs[3]);
        double tau = mxGetScalar(prhs[2]);
        int off = geti(prhs[4]);
        Buf c = balloc((size_t)(m * n), off), v = balloc((size_t)m, off), work = balloc((size_t)(n + m), 0);
        memcpy(c.p, mxGetDoubles(prhs[3]), (size_t)(m * n) * 8);
        memcpy(v.p, mxGetDoubles(prhs[1]), (size_t)m * 8);
        dlarf_("L", &m, &n, v.p, &ONE, &tau, c.p, &m, work.p);
        plhs[0] = mkmat((size_t)m, (size_t)n);
        memcpy(mxGetDoubles(plhs[0]), c.p, (size_t)(m * n) * 8);
        bfree(c); bfree(v); bfree(work);
    } else if (!strcmp(cmd, "factor")) { /* (method,A,off) -> [packed A; tau row] */
        int method = geti(prhs[1]), off = geti(prhs[3]);
        I n = (I)mxGetM(prhs[2]), p = (I)mxGetN(prhs[2]), info = 0, lwork = 64 * (n + p) + 4096;
        Buf a = balloc((size_t)(n * p), off), tau = balloc((size_t)p, 0), work = balloc((size_t)lwork, 0);
        I *jpvt = (I *)calloc((size_t)p, sizeof(I));
        memcpy(a.p, mxGetDoubles(prhs[2]), (size_t)(n * p) * 8);
        if (method == 1) dgeqp3_(&n, &p, a.p, &n, jpvt, tau.p, work.p, &lwork, &info);
        else if (method == 3) dgeqrf_(&n, &p, a.p, &n, tau.p, work.p, &lwork, &info);
        else if (method == 4) dgeqr2_(&n, &p, a.p, &n, tau.p, work.p, &info);
        else ref_geqr2(n, p, a.p, n, tau.p, work.p);
        plhs[0] = mkmat((size_t)(n + 2), (size_t)p);
        double *o = mxGetDoubles(plhs[0]);
        for (I j = 0; j < p; j++) {
            memcpy(o + j * (n + 2), a.p + j * n, (size_t)n * 8);
            o[n + j * (n + 2)] = tau.p[j];
            o[n + 1 + j * (n + 2)] = (double)jpvt[j];
        }
        free(jpvt); bfree(a); bfree(tau); bfree(work);
    } else if (!strcmp(cmd, "applyq")) { /* (method,packedA(n-by-p),tau,C,off) -> Q'*C */
        int method = geti(prhs[1]), off = geti(prhs[5]);
        I n = (I)mxGetM(prhs[2]), p = (I)mxGetN(prhs[2]), w = (I)mxGetN(prhs[4]), info = 0;
        I lwork = 64 * (n + p + w) + 4096;
        Buf a = balloc((size_t)(n * p), off), c = balloc((size_t)(n * w), off), work = balloc((size_t)lwork, 0);
        memcpy(a.p, mxGetDoubles(prhs[2]), (size_t)(n * p) * 8);
        memcpy(c.p, mxGetDoubles(prhs[4]), (size_t)(n * w) * 8);
        const double *tau = mxGetDoubles(prhs[3]);
        if (method == 1) dormqr_("L", "T", &n, &w, &p, a.p, &n, tau, c.p, &n, work.p, &lwork, &info);
        else if (method == 2) dorm2r_("L", "T", &n, &w, &p, a.p, &n, tau, c.p, &n, work.p, &info);
        else ref_orm2r(n, w, p, a.p, n, tau, c.p, n, work.p);
        plhs[0] = mkmat((size_t)n, (size_t)w);
        memcpy(mxGetDoubles(plhs[0]), c.p, (size_t)(n * w) * 8);
        bfree(a); bfree(c); bfree(work);
    } else if (!strcmp(cmd, "solve")) { /* (method,X,B,off) */
        int method = geti(prhs[1]), off = geti(prhs[4]);
        I n = (I)mxGetM(prhs[2]), p = (I)mxGetN(prhs[2]), w = (I)mxGetN(prhs[3]);
        double info = 0.0;
        plhs[0] = mkmat((size_t)p, (size_t)w);
        solve(method, off, n, p, w, mxGetDoubles(prhs[2]), mxGetDoubles(prhs[3]), mxGetDoubles(plhs[0]), &info);
        if (nlhs > 1) plhs[1] = mxCreateDoubleScalar(info);
    } else if (!strcmp(cmd, "fprev_dot")) { /* (n,offx,offy) -> n-by-n */
        I n = (I)geti(prhs[1]);
        Buf x = balloc((size_t)n, geti(prhs[2])), y = balloc((size_t)n, geti(prhs[3]));
        plhs[0] = mkmat((size_t)n, (size_t)n);
        double *L = mxGetDoubles(plhs[0]);
        for (I i = 0; i < n; i++) { x.p[i] = 1.0; y.p[i] = 1.0; }
        for (I i = 0; i < n; i++)
            for (I j = i + 1; j < n; j++) {
                x.p[i] = M; x.p[j] = -M;
                double r = ddot_(&n, x.p, &ONE, y.p, &ONE);
                L[i + j * n] = r; L[j + i * n] = r;
                x.p[i] = 1.0; x.p[j] = 1.0;
            }
        bfree(x); bfree(y);
    } else if (!strcmp(cmd, "fprev_nrm2sq")) { /* (n,off): one big element at i -> n-by-1 of nrm2^2 probes */
        I n = (I)geti(prhs[1]);
        Buf x = balloc((size_t)n, geti(prhs[2]));
        plhs[0] = mkmat((size_t)n, 1);
        double *L = mxGetDoubles(plhs[0]);
        for (I i = 0; i < n; i++) x.p[i] = 1.0;
        for (I i = 0; i < n; i++) {
            x.p[i] = 134217728.0; /* 2^27, square 2^54 */
            L[i] = dnrm2_(&n, x.p, &ONE);
            x.p[i] = 1.0;
        }
        bfree(x);
    } else if (!strcmp(cmd, "fprev_gemvT")) { /* (m,ncols,offA,offx,ldaextra) -> m-by-m-by-ncols */
        I m = (I)geti(prhs[1]), nc = (I)geti(prhs[2]);
        I lda = m + geti(prhs[5]);
        Buf a = balloc((size_t)(lda * nc), geti(prhs[3])), x = balloc((size_t)m, geti(prhs[4])), y = balloc((size_t)nc, 0);
        mwSize dims[3] = {(mwSize)m, (mwSize)m, (mwSize)nc};
        plhs[0] = mxCreateNumericArray(3, dims, mxDOUBLE_CLASS, mxREAL);
        double *L = mxGetDoubles(plhs[0]);
        for (I i = 0; i < m; i++) x.p[i] = 1.0;
        for (I c = 0; c < nc; c++) for (I i = 0; i < m; i++) a.p[i + c * lda] = 1.0;
        for (I i = 0; i < m; i++)
            for (I j = i + 1; j < m; j++) {
                for (I c = 0; c < nc; c++) { a.p[i + c * lda] = M; a.p[j + c * lda] = -M; }
                dgemv_("T", &m, &nc, &D1, a.p, &lda, x.p, &ONE, &D0, y.p, &ONE);
                for (I c = 0; c < nc; c++) {
                    L[i + j * m + c * m * m] = y.p[c]; L[j + i * m + c * m * m] = y.p[c];
                    a.p[i + c * lda] = 1.0; a.p[j + c * lda] = 1.0;
                }
            }
        bfree(a); bfree(x); bfree(y);
    } else if (!strcmp(cmd, "fprev_gemvN")) { /* (m,ncols) -> ncols-by-ncols-by-m */
        I m = (I)geti(prhs[1]), nc = (I)geti(prhs[2]);
        Buf a = balloc((size_t)(m * nc), 0), x = balloc((size_t)nc, 0), y = balloc((size_t)m, 0);
        mwSize dims[3] = {(mwSize)nc, (mwSize)nc, (mwSize)m};
        plhs[0] = mxCreateNumericArray(3, dims, mxDOUBLE_CLASS, mxREAL);
        double *L = mxGetDoubles(plhs[0]);
        for (I c = 0; c < nc; c++) { x.p[c] = 1.0; for (I i = 0; i < m; i++) a.p[i + c * m] = 1.0; }
        for (I i = 0; i < nc; i++)
            for (I j = i + 1; j < nc; j++) {
                for (I r = 0; r < m; r++) { a.p[r + i * m] = M; a.p[r + j * m] = -M; }
                dgemv_("N", &m, &nc, &D1, a.p, &m, x.p, &ONE, &D0, y.p, &ONE);
                for (I r = 0; r < m; r++) {
                    L[i + j * nc + r * nc * nc] = y.p[r]; L[j + i * nc + r * nc * nc] = y.p[r];
                    a.p[r + i * m] = 1.0; a.p[r + j * m] = 1.0;
                }
            }
        bfree(a); bfree(x); bfree(y);
    } else if (!strcmp(cmd, "fprev_larf")) {
        /* (m,ncols,off): tree of w=C'v inside dlarf('L'). v=ones (v(1)=1), tau=1,
           C(:,c) masked; returns row 1 of H*C = C(1,c) - w_c, as m-by-m-by-ncols of w_c. */
        I m = (I)geti(prhs[1]), nc = (I)geti(prhs[2]);
        int off = geti(prhs[3]);
        Buf c = balloc((size_t)(m * nc), off), v = balloc((size_t)m, off), work = balloc((size_t)(nc + m), 0);
        mwSize dims[3] = {(mwSize)m, (mwSize)m, (mwSize)nc};
        plhs[0] = mxCreateNumericArray(3, dims, mxDOUBLE_CLASS, mxREAL);
        double *L = mxGetDoubles(plhs[0]);
        /* choose tau=1 and v=ones: H*C row r = C(r,c) - w_c. Put masks in rows i,j and
           read w_c from a row r that holds exactly 1 (r != i,j): out = 1 - w_c. */
        for (I i = 0; i < m; i++)
            for (I j = i + 1; j < m; j++) {
                for (I k = 0; k < m; k++) v.p[k] = 1.0;
                for (I q = 0; q < nc; q++) {
                    for (I k = 0; k < m; k++) c.p[k + q * m] = 1.0;
                    c.p[i + q * m] = M; c.p[j + q * m] = -M;
                }
                double tau = 1.0;
                dlarf_("L", &m, &nc, v.p, &ONE, &tau, c.p, &m, work.p);
                I r = 0; while (r == i || r == j) r++;
                for (I q = 0; q < nc; q++) {
                    double wq = (m > 2) ? 1.0 - c.p[r + q * m] : 0.0;
                    L[i + j * m + q * m * m] = wq; L[j + i * m + q * m * m] = wq;
                }
            }
        bfree(c); bfree(v); bfree(work);
    } else if (!strcmp(cmd, "ormqr_variants")) { /* (V,tau,C) -> m-by-w-by-19 */
        I m = (I)mxGetM(prhs[1]), k = (I)mxGetN(prhs[1]), w = (I)mxGetN(prhs[3]), info = 0;
        I lwork = 64 * (m + k + w) + 4096;
        const int NV = 19;
        static const int tk[19] = {0,0,0,1,0,1,2,2,0,0,0,0,1,1,1,0,0,0,0};
        static const int ak[19] = {0,0,0,0,1,1,1,0,0,0,0,0,1,1,1,0,0,0,0};
        static const int nbv[19] = {0,0,0,0,0,0,0,0,1,2,4,8,1,4,8,3,6,12,16};
        mwSize dims[3] = {(mwSize)m, (mwSize)w, (mwSize)NV};
        plhs[0] = mxCreateNumericArray(3, dims, mxDOUBLE_CLASS, mxREAL);
        double *O = mxGetDoubles(plhs[0]);
        Buf v = balloc((size_t)(m * k), 0), c = balloc((size_t)(m * w), 0), work = balloc((size_t)lwork, 0);
        const double *tau = mxGetDoubles(prhs[2]);
        for (int q = 0; q < NV; q++) {
            memcpy(v.p, mxGetDoubles(prhs[1]), (size_t)(m * k) * 8);
            memcpy(c.p, mxGetDoubles(prhs[3]), (size_t)(m * w) * 8);
            if (q == 0) dormqr_("L", "T", &m, &w, &k, v.p, &m, tau, c.p, &m, work.p, &lwork, &info);
            else if (q == 1) dorm2r_("L", "T", &m, &w, &k, v.p, &m, tau, c.p, &m, work.p, &info);
            else apply_blocked(tk[q], ak[q], nbv[q] ? nbv[q] : k, m, w, k, v.p, m, tau, c.p, m);
            memcpy(O + (size_t)q * m * w, c.p, (size_t)(m * w) * 8);
        }
        bfree(v); bfree(c); bfree(work);
    } else if (!strcmp(cmd, "larft_variants")) { /* (V,tau) -> k-by-k-by-3 */
        I m = (I)mxGetM(prhs[1]), k = (I)mxGetN(prhs[1]);
        mwSize dims[3] = {(mwSize)k, (mwSize)k, 3};
        plhs[0] = mxCreateNumericArray(3, dims, mxDOUBLE_CLASS, mxREAL);
        double *O = mxGetDoubles(plhs[0]);
        const double *v = mxGetDoubles(prhs[1]), *tau = mxGetDoubles(prhs[2]);
        dlarft_("F", "C", &m, &k, v, &m, tau, O, &k);
        ref_larft_nonrec(m, k, v, m, tau, O + k * k, k);
        ref_larft_rec(m, k, v, m, tau, O + 2 * k * k, k);
    } else if (!strcmp(cmd, "ormqr_T")) { /* (V,tau): V rows k..2k-1 must be identity -> T read through dormqr */
        I m = (I)mxGetM(prhs[1]), k = (I)mxGetN(prhs[1]), info = 0, lwork = 64 * (m + 2 * k) + 4096;
        Buf v = balloc((size_t)(m * k), 0), c = balloc((size_t)(m * k), 0), work = balloc((size_t)lwork, 0);
        memcpy(v.p, mxGetDoubles(prhs[1]), (size_t)(m * k) * 8);
        for (I l = 0; l < k; l++) c.p[(k + l) + l * m] = 1.0;
        dormqr_("L", "T", &m, &k, &k, v.p, &m, mxGetDoubles(prhs[2]), c.p, &m, work.p, &lwork, &info);
        plhs[0] = mkmat((size_t)k, (size_t)k);
        double *O = mxGetDoubles(plhs[0]);
        for (I l = 0; l < k; l++) for (I r = 0; r < k; r++) O[l + r * k] = ((l == r) ? 1.0 : 0.0) - c.p[(k + r) + l * m];
        bfree(v); bfree(c); bfree(work);
    } else if (!strcmp(cmd, "gemm")) { /* (ta,tb,alpha,A,B,beta,C) */
        int ta = geti(prhs[1]), tb = geti(prhs[2]);
        double alpha = mxGetScalar(prhs[3]), beta = mxGetScalar(prhs[6]);
        I ma = (I)mxGetM(prhs[4]), na = (I)mxGetN(prhs[4]), mb = (I)mxGetM(prhs[5]), nbb = (I)mxGetN(prhs[5]);
        I m = ta ? na : ma, kk = ta ? ma : na, n = tb ? mb : nbb;
        plhs[0] = mxDuplicateArray(prhs[7]);
        dgemm_(ta ? "T" : "N", tb ? "T" : "N", &m, &n, &kk, &alpha, mxGetDoubles(prhs[4]), &ma,
               mxGetDoubles(prhs[5]), &mb, &beta, mxGetDoubles(plhs[0]), &m);
    } else if (!strcmp(cmd, "trmm")) { /* (variant,W,Tri): 1 W*V1 (R,L,N,U) 2 W*T (R,U,N,N) 3 W*V1' (R,L,T,U) 4 -T11*X (L,U,N,N,alpha=-1) */
        int var = geti(prhs[1]);
        I w = (I)mxGetM(prhs[2]), k = (I)mxGetN(prhs[2]), lt = (I)mxGetM(prhs[3]);
        plhs[0] = mxDuplicateArray(prhs[2]);
        double *W = mxGetDoubles(plhs[0]);
        const double *Tm = mxGetDoubles(prhs[3]);
        if (var == 1) dtrmm_("R", "L", "N", "U", &w, &k, &D1, Tm, &lt, W, &w);
        else if (var == 2) dtrmm_("R", "U", "N", "N", &w, &k, &D1, Tm, &lt, W, &w);
        else if (var == 3) dtrmm_("R", "L", "T", "U", &w, &k, &D1, Tm, &lt, W, &w);
        else dtrmm_("L", "U", "N", "N", &w, &k, &DM1, Tm, &lt, W, &w);
    } else if (!strcmp(cmd, "trmv")) { /* (T,x) upper notrans nonunit */
        I n = (I)mxGetM(prhs[1]);
        plhs[0] = mxDuplicateArray(prhs[2]);
        dtrmv_("U", "N", "N", &n, mxGetDoubles(prhs[1]), &n, mxGetDoubles(plhs[0]), &ONE);
    } else if (!strcmp(cmd, "fprev_gemmTN")) { /* (w,k,L): W(w-by-k) += C2'(L-by-w) * V2(L-by-k); leaves rows 0..L-1 and init L */
        int w = geti(prhs[1]), k = geti(prhs[2]), L = geti(prhs[3]), n = L + 1, nout = w * k;
        I wi = w, ki = k, Li = L;
        Buf c2 = balloc((size_t)(L * w), 0), v2 = balloc((size_t)(L * k), 0), W = balloc((size_t)nout, 0);
        uint8_t *tab = calloc((size_t)nout * n * n, 1), *scr = malloc((size_t)n * n);
        for (int i = 0; i < L * k; i++) v2.p[i] = 1.0;
        for (int a = 0; a < n; a++)
            for (int b = a + 1; b < n; b++) {
                for (int i = 0; i < L * w; i++) c2.p[i] = 1.0;
                for (int i = 0; i < nout; i++) W.p[i] = 1.0;
                if (a < L) for (int q = 0; q < w; q++) c2.p[a + q * L] = BIGM;
                if (b < L) for (int q = 0; q < w; q++) c2.p[b + q * L] = -BIGM;
                else for (int i = 0; i < nout; i++) W.p[i] = -BIGM;
                dgemm_("T", "N", &wi, &ki, &Li, &D1, c2.p, &Li, v2.p, &Li, &D1, W.p, &wi);
                for (int o = 0; o < nout; o++) { uint8_t r = clampcount(W.p[o]); tab[(size_t)o * n * n + a * n + b] = r; tab[(size_t)o * n * n + b * n + a] = r; }
            }
        idx_put(10); idx_put(w); idx_put(k); idx_put(L); idx_put(0); idx_put(nout);
        reg_outputs(tab, n, nout, NULL, NULL, scr);
        free(tab); free(scr); bfree(c2); bfree(v2); bfree(W);
    } else if (!strcmp(cmd, "fprev_gemmNT")) { /* (L,w,k): C2(L-by-w) -= V2(L-by-k) * W(w-by-k)'; leaves j 0..k-1 and init k */
        int L = geti(prhs[1]), w = geti(prhs[2]), k = geti(prhs[3]), n = k + 1, nout = L * w;
        I wi = w, ki = k, Li = L;
        Buf c2 = balloc((size_t)nout, 0), v2 = balloc((size_t)(L * k), 0), W = balloc((size_t)(w * k), 0);
        uint8_t *tab = calloc((size_t)nout * n * n, 1), *scr = malloc((size_t)n * n);
        for (int i = 0; i < L * k; i++) v2.p[i] = 1.0;
        for (int a = 0; a < n; a++)
            for (int b = a + 1; b < n; b++) {
                for (int i = 0; i < w * k; i++) W.p[i] = 1.0;
                for (int i = 0; i < nout; i++) c2.p[i] = -1.0;
                for (int q = 0; q < w; q++) W.p[q + a * w] = -BIGM;
                if (b < k) for (int q = 0; q < w; q++) W.p[q + b * w] = BIGM;
                else for (int i = 0; i < nout; i++) c2.p[i] = -BIGM;
                dgemm_("N", "T", &Li, &wi, &ki, &DM1, v2.p, &Li, W.p, &wi, &D1, c2.p, &Li);
                for (int o = 0; o < nout; o++) { uint8_t r = clampcount(-c2.p[o]); tab[(size_t)o * n * n + a * n + b] = r; tab[(size_t)o * n * n + b * n + a] = r; }
            }
        idx_put(11); idx_put(L); idx_put(w); idx_put(k); idx_put(0); idx_put(nout);
        reg_outputs(tab, n, nout, NULL, NULL, scr);
        free(tab); free(scr); bfree(c2); bfree(v2); bfree(W);
    } else if (!strcmp(cmd, "fprev_trmm")) { /* (variant,w,k): leaves are columns of W */
        int var = geti(prhs[1]), w = geti(prhs[2]), k = geti(prhs[3]), n = k, nout = w * k;
        I wi = w, ki = k;
        Buf W = balloc((size_t)nout, 0), Tm = balloc((size_t)(k * k), 0);
        uint8_t *tab = calloc((size_t)nout * n * n, 1), *scr = malloc((size_t)n * n);
        int *lo = malloc(sizeof(int) * (size_t)nout), *hi = malloc(sizeof(int) * (size_t)nout);
        for (int i = 0; i < k * k; i++) Tm.p[i] = 1.0;
        for (int j = 0; j < k; j++) for (int q = 0; q < w; q++) {
            int o = q + j * w;
            if (var == 1) { lo[o] = j; hi[o] = k; } else { lo[o] = 0; hi[o] = j + 1; }
        }
        for (int a = 0; a < n; a++)
            for (int b = a + 1; b < n; b++) {
                for (int i = 0; i < nout; i++) W.p[i] = 1.0;
                for (int q = 0; q < w; q++) { W.p[q + a * w] = BIGM; W.p[q + b * w] = -BIGM; }
                if (var == 1) dtrmm_("R", "L", "N", "U", &wi, &ki, &D1, Tm.p, &ki, W.p, &wi);
                else if (var == 2) dtrmm_("R", "U", "N", "N", &wi, &ki, &D1, Tm.p, &ki, W.p, &wi);
                else dtrmm_("R", "L", "T", "U", &wi, &ki, &D1, Tm.p, &ki, W.p, &wi);
                for (int o = 0; o < nout; o++) {
                    int s = hi[o] - lo[o];
                    uint8_t r = (a >= lo[o] && b < hi[o]) ? clampcount((double)s - W.p[o]) : 0;
                    /* store n-|LCA| in the local leaf count convention */
                    r = (a >= lo[o] && b < hi[o]) ? clampcount(W.p[o]) : 0;
                    tab[(size_t)o * n * n + a * n + b] = r; tab[(size_t)o * n * n + b * n + a] = r;
                }
            }
        idx_put(12); idx_put(var); idx_put(w); idx_put(k); idx_put(0); idx_put(nout);
        reg_outputs(tab, n, nout, lo, hi, scr);
        free(tab); free(scr); free(lo); free(hi); bfree(W); bfree(Tm);
    } else if (!strcmp(cmd, "fprev_trmv")) { /* (n): x := T x, upper; output l has leaves l..n-1 */
        int n = geti(prhs[1]);
        I ni = n;
        Buf x = balloc((size_t)n, 0), Tm = balloc((size_t)(n * n), 0);
        uint8_t *tab = calloc((size_t)n * n * n, 1), *scr = malloc((size_t)n * n);
        int *lo = malloc(sizeof(int) * (size_t)n), *hi = malloc(sizeof(int) * (size_t)n);
        for (int i = 0; i < n * n; i++) Tm.p[i] = 1.0;
        for (int o = 0; o < n; o++) { lo[o] = o; hi[o] = n; }
        for (int a = 0; a < n; a++)
            for (int b = a + 1; b < n; b++) {
                for (int i = 0; i < n; i++) x.p[i] = 1.0;
                x.p[a] = BIGM; x.p[b] = -BIGM;
                dtrmv_("U", "N", "N", &ni, Tm.p, &ni, x.p, &ONE);
                for (int o = 0; o < n; o++) { uint8_t r = (a >= o) ? clampcount(x.p[o]) : 0; tab[(size_t)o * n * n + a * n + b] = r; tab[(size_t)o * n * n + b * n + a] = r; }
            }
        idx_put(13); idx_put(n); idx_put(0); idx_put(0); idx_put(0); idx_put(n);
        reg_outputs(tab, n, n, lo, hi, scr);
        free(tab); free(scr); free(lo); free(hi); bfree(x); bfree(Tm);
    } else if (!strcmp(cmd, "fprev_trsm")) { /* (p,w): for each row i, x_i = b_i - sum_{k>i} x_k; leaves i..p-1 */
        int p = geti(prhs[1]), w = geti(prhs[2]), n = p, nout = w;
        I pi = p, wi = w;
        Buf R = balloc((size_t)(p * p), 0), B = balloc((size_t)(p * w), 0);
        uint8_t *tab = calloc((size_t)nout * n * n, 1), *scr = malloc((size_t)n * n);
        int *lo = malloc(sizeof(int) * (size_t)nout), *hi = malloc(sizeof(int) * (size_t)nout);
        for (int i = 0; i < p - 1; i++) {
            memset(R.p, 0, (size_t)(p * p) * 8);
            for (int d = 0; d < p; d++) R.p[d + d * p] = 1.0;
            for (int kk = i + 1; kk < p; kk++) R.p[i + kk * p] = 1.0;
            memset(tab, 0, (size_t)nout * n * n);
            for (int a = i; a < p; a++)
                for (int b = a + 1; b < p; b++) {
                    for (int q = 0; q < w; q++) {
                        for (int r = 0; r < p; r++) B.p[r + q * p] = (r < i) ? 0.0 : (r == i ? -1.0 : 1.0);
                        B.p[a + q * p] = (a == i) ? BIGM : -BIGM;
                        B.p[b + q * p] = BIGM; /* leaf b>i contributes -x_b = -BIGM */
                    }
                    dtrsm_("L", "U", "N", "N", &pi, &wi, &D1, R.p, &pi, B.p, &pi);
                    for (int q = 0; q < w; q++) { uint8_t r = clampcount(-B.p[i + q * p]); tab[(size_t)q * n * n + a * n + b] = r; tab[(size_t)q * n * n + b * n + a] = r; }
                }
            for (int q = 0; q < w; q++) { lo[q] = i; hi[q] = p; }
            idx_put(14); idx_put(p); idx_put(w); idx_put(i); idx_put(0); idx_put(nout);
            reg_outputs(tab, n, nout, lo, hi, scr);
        }
        free(tab); free(scr); free(lo); free(hi); bfree(R); bfree(B);
    } else if (!strcmp(cmd, "fprev_ormqr")) { /* (m,k,w,i): tree of W(c,i)=C(:,c)'v_i inside dormqr, leaves rows i..m-1 */
        int m = geti(prhs[1]), k = geti(prhs[2]), w = geti(prhs[3]), i0 = geti(prhs[4]), n = m - i0, nout = w;
        I mi = m, ki = k, wi = w, info = 0, lwork = 64 * (m + k + w) + 4096;
        Buf v = balloc((size_t)(m * k), 0), c = balloc((size_t)(m * w), 0), tau = balloc((size_t)k, 0), work = balloc((size_t)lwork, 0);
        uint8_t *tab = calloc((size_t)nout * n * n, 1), *scr = malloc((size_t)n * n);
        tau.p[i0] = 1.0;
        if (n >= 3) {
            for (int a = 0; a < n; a++)
                for (int b = a + 1; b < n; b++) {
                    for (int j = 0; j < k; j++) for (int r = 0; r < m; r++) v.p[r + j * m] = (r >= j) ? 1.0 : 0.0;
                    for (int q = 0; q < m * w; q++) c.p[q] = 1.0;
                    for (int q = 0; q < w; q++) { c.p[(i0 + a) + q * m] = BIGM; c.p[(i0 + b) + q * m] = -BIGM; }
                    dormqr_("L", "T", &mi, &wi, &ki, v.p, &mi, tau.p, c.p, &mi, work.p, &lwork, &info);
                    int r = 0; while (r == a || r == b) r++;
                    for (int q = 0; q < w; q++) { uint8_t cnt = clampcount(1.0 - c.p[(i0 + r) + q * m]); tab[(size_t)q * n * n + a * n + b] = cnt; tab[(size_t)q * n * n + b * n + a] = cnt; }
                }
        }
        idx_put(15); idx_put(m); idx_put(k); idx_put(w); idx_put(i0); idx_put(nout);
        reg_outputs(tab, n, nout, NULL, NULL, scr);
        free(tab); free(scr); bfree(v); bfree(c); bfree(tau); bfree(work);
    } else if (!strcmp(cmd, "orgq")) { /* (method,packed m-by-k,tau) -> explicit economy Q */
        int method = geti(prhs[1]);
        I m = (I)mxGetM(prhs[2]), k = (I)mxGetN(prhs[2]), info = 0, lwork = 64 * (m + k) + 4096;
        const double *tau = mxGetDoubles(prhs[3]);
        Buf a = balloc((size_t)(m * k), 0), work = balloc((size_t)lwork, 0);
        memcpy(a.p, mxGetDoubles(prhs[2]), (size_t)(m * k) * 8);
        if (method == 0) dorgqr_(&m, &k, &k, a.p, &m, tau, work.p, &lwork, &info);
        else if (method == 1) dorg2r_(&m, &k, &k, a.p, &m, tau, work.p, &info);
        else if (method == 2 || method == 3) {
            Buf c = balloc((size_t)(m * k), 0);
            for (I i = 0; i < k; i++) c.p[i + i * m] = 1.0;
            if (method == 2) dormqr_("L", "N", &m, &k, &k, a.p, &m, tau, c.p, &m, work.p, &lwork, &info);
            else dorm2r_("L", "N", &m, &k, &k, a.p, &m, tau, c.p, &m, work.p, &info);
            memcpy(a.p, c.p, (size_t)(m * k) * 8);
            bfree(c);
        } else {
            I nb = method == 4 ? 4 : method == 5 ? 8 : method == 6 ? 16 : 32;
            ref_orgqr_blk(m, k, k, nb, a.p, m, tau);
        }
        plhs[0] = mkmat((size_t)m, (size_t)k);
        memcpy(mxGetDoubles(plhs[0]), a.p, (size_t)(m * k) * 8);
        bfree(a); bfree(work);
    } else if (!strcmp(cmd, "trsmR")) { /* (R p-by-p, B n-by-p, off) -> B/R, right upper notrans nonunit */
        I p = (I)mxGetM(prhs[1]), n = (I)mxGetM(prhs[2]);
        int off = geti(prhs[3]);
        Buf b = balloc((size_t)(n * p), off), r = balloc((size_t)(p * p), off);
        memcpy(b.p, mxGetDoubles(prhs[2]), (size_t)(n * p) * 8);
        memcpy(r.p, mxGetDoubles(prhs[1]), (size_t)(p * p) * 8);
        dtrsm_("R", "U", "N", "N", &n, &p, &D1, r.p, &p, b.p, &n);
        plhs[0] = mkmat((size_t)n, (size_t)p);
        memcpy(mxGetDoubles(plhs[0]), b.p, (size_t)(n * p) * 8);
        bfree(b); bfree(r);
    } else if (!strcmp(cmd, "syrk")) { /* (lowerflag, A p-by-k) -> p-by-p, only that triangle filled */
        int lower = geti(prhs[1]);
        I p = (I)mxGetM(prhs[2]), k = (I)mxGetN(prhs[2]);
        plhs[0] = mkmat((size_t)p, (size_t)p);
        dsyrk_(lower ? "L" : "U", "N", &p, &k, &D1, mxGetDoubles(prhs[2]), &p, &D0, mxGetDoubles(plhs[0]), &p);
    } else if (!strcmp(cmd, "trtri")) { /* (R) -> inv(R), upper nonunit */
        I p = (I)mxGetM(prhs[1]), info = 0;
        plhs[0] = mxDuplicateArray(prhs[1]);
        dtrtri_("U", "N", &p, mxGetDoubles(plhs[0]), &p, &info);
    } else if (!strcmp(cmd, "gemv2")) { /* (transflag,alpha,A,x,beta,y) */
        int tr = geti(prhs[1]);
        double alpha = mxGetScalar(prhs[2]), beta = mxGetScalar(prhs[5]);
        I m = (I)mxGetM(prhs[3]), n = (I)mxGetN(prhs[3]);
        plhs[0] = mxDuplicateArray(prhs[6]);
        dgemv_(tr ? "T" : "N", &m, &n, &alpha, mxGetDoubles(prhs[3]), &m, mxGetDoubles(prhs[4]), &ONE, &beta,
               mxGetDoubles(plhs[0]), &ONE);
    } else if (!strcmp(cmd, "fprev_gemvN2")) { /* (m,nc,mode): mode 0 y=A*x; mode 1 y=y-A*x with init leaf nc */
        int m = geti(prhs[1]), nc = geti(prhs[2]), mode = geti(prhs[3]), n = nc + (mode ? 1 : 0);
        I mi = m, ni = nc;
        double alpha = mode ? -1.0 : 1.0, beta = mode ? 1.0 : 0.0;
        Buf a = balloc((size_t)(m * nc), 0), x = balloc((size_t)nc, 0), y = balloc((size_t)m, 0);
        uint8_t *tab = calloc((size_t)m * n * n + 1, 1), *scr = malloc((size_t)n * n + 1);
        for (int aa = 0; aa < n; aa++)
            for (int bb = aa + 1; bb < n; bb++) {
                for (int i = 0; i < m * nc; i++) a.p[i] = 1.0;
                for (int i = 0; i < nc; i++) x.p[i] = mode ? -1.0 : 1.0;
                for (int i = 0; i < m; i++) y.p[i] = mode ? 1.0 : 0.0;
                for (int r = 0; r < m; r++) a.p[r + aa * m] = BIGM;
                if (bb < nc) for (int r = 0; r < m; r++) a.p[r + bb * m] = -BIGM;
                else for (int r = 0; r < m; r++) y.p[r] = -BIGM;
                dgemv_("N", &mi, &ni, &alpha, a.p, &mi, x.p, &ONE, &beta, y.p, &ONE);
                for (int r = 0; r < m; r++) { uint8_t c = clampcount(y.p[r]); tab[(size_t)r * n * n + aa * n + bb] = c; tab[(size_t)r * n * n + bb * n + aa] = c; }
            }
        idx_put(20); idx_put(m); idx_put(nc); idx_put(mode); idx_put(0); idx_put(m);
        reg_outputs(tab, n, m, NULL, NULL, scr);
        free(tab); free(scr); bfree(a); bfree(x); bfree(y);
    } else if (!strcmp(cmd, "fprev_trsmR")) { /* (n,p): E=X/R; for column j, E(i,j)=x_ij+sum_{k<j} x_ik; leaves 0..j */
        int n = geti(prhs[1]), p = geti(prhs[2]);
        I ni = n, pi = p;
        Buf R = balloc((size_t)(p * p), 0), B = balloc((size_t)(n * p), 0);
        uint8_t *tab = calloc((size_t)n * p * p + 1, 1), *scr = malloc((size_t)p * p + 1);
        for (int j = 1; j < p; j++) {
            int nl = j + 1;
            memset(R.p, 0, (size_t)(p * p) * 8);
            for (int d = 0; d < p; d++) R.p[d + d * p] = 1.0;
            for (int kk = 0; kk < j; kk++) R.p[kk + j * p] = -1.0;
            memset(tab, 0, (size_t)n * nl * nl);
            for (int aa = 0; aa < nl; aa++)
                for (int bb = aa + 1; bb < nl; bb++) {
                    for (int i = 0; i < n * p; i++) B.p[i] = 1.0;
                    for (int r = 0; r < n; r++) { B.p[r + aa * n] = BIGM; B.p[r + bb * n] = -BIGM; }
                    dtrsm_("R", "U", "N", "N", &ni, &pi, &D1, R.p, &pi, B.p, &ni);
                    for (int r = 0; r < n; r++) { uint8_t c = clampcount(B.p[r + j * n]); tab[(size_t)r * nl * nl + aa * nl + bb] = c; tab[(size_t)r * nl * nl + bb * nl + aa] = c; }
                }
            idx_put(21); idx_put(n); idx_put(p); idx_put(j); idx_put(0); idx_put(n);
            reg_outputs(tab, nl, n, NULL, NULL, scr);
        }
        free(tab); free(scr); bfree(R); bfree(B);
    } else if (!strcmp(cmd, "fprev_syrk")) { /* (p,k,lowerflag): C=A*A'; tree of C(i,j), j~=i, over the k products */
        int p = geti(prhs[1]), k = geti(prhs[2]), lower = geti(prhs[3]);
        I pi = p, ki = k;
        Buf A = balloc((size_t)(p * k), 0), C = balloc((size_t)(p * p), 0);
        uint8_t *tab = calloc((size_t)p * k * k + 1, 1), *scr = malloc((size_t)k * k + 1);
        int *lo = malloc(sizeof(int) * (size_t)p), *hi = malloc(sizeof(int) * (size_t)p);
        for (int i = 0; i < p; i++) {
            memset(tab, 0, (size_t)p * k * k);
            for (int aa = 0; aa < k; aa++)
                for (int bb = aa + 1; bb < k; bb++) {
                    for (int q = 0; q < p * k; q++) A.p[q] = 1.0;
                    A.p[i + aa * p] = BIGM; A.p[i + bb * p] = -BIGM;
                    memset(C.p, 0, (size_t)(p * p) * 8);
                    dsyrk_(lower ? "L" : "U", "N", &pi, &ki, &D1, A.p, &pi, &D0, C.p, &pi);
                    for (int j = 0; j < p; j++) {
                        if (j == i) continue;
                        int r = lower ? (i > j ? i : j) : (i < j ? i : j), c = lower ? (i > j ? j : i) : (i < j ? j : i);
                        uint8_t cnt = clampcount(C.p[r + c * p]);
                        tab[(size_t)j * k * k + aa * k + bb] = cnt; tab[(size_t)j * k * k + bb * k + aa] = cnt;
                    }
                }
            for (int j = 0; j < p; j++) { lo[j] = 0; hi[j] = (j == i) ? 0 : k; }
            idx_put(22); idx_put(p); idx_put(k); idx_put(i); idx_put(lower); idx_put(p);
            reg_outputs(tab, k, p, lo, hi, scr);
        }
        free(tab); free(scr); free(lo); free(hi); bfree(A); bfree(C);
    } else if (!strcmp(cmd, "fprev_gemmNT0")) { /* (m,n2,k): C(m-by-n2)=A(m-by-k)*B(n2-by-k)'; leaves are the k products */
        int m = geti(prhs[1]), n2 = geti(prhs[2]), k = geti(prhs[3]), nout = m * n2;
        I mi = m, n2i = n2, ki = k;
        Buf A = balloc((size_t)(m * k), 0), B = balloc((size_t)(n2 * k), 0), C = balloc((size_t)nout, 0);
        uint8_t *tab = calloc((size_t)nout * k * k + 1, 1), *scr = malloc((size_t)k * k + 1);
        for (int q = 0; q < m * k; q++) A.p[q] = 1.0;
        for (int aa = 0; aa < k; aa++)
            for (int bb = aa + 1; bb < k; bb++) {
                for (int q = 0; q < n2 * k; q++) B.p[q] = 1.0;
                for (int q = 0; q < n2; q++) { B.p[q + aa * n2] = BIGM; B.p[q + bb * n2] = -BIGM; }
                dgemm_("N", "T", &mi, &n2i, &ki, &D1, A.p, &mi, B.p, &n2i, &D0, C.p, &mi);
                for (int o = 0; o < nout; o++) { uint8_t c = clampcount(C.p[o]); tab[(size_t)o * k * k + aa * k + bb] = c; tab[(size_t)o * k * k + bb * k + aa] = c; }
            }
        idx_put(23); idx_put(m); idx_put(n2); idx_put(k); idx_put(0); idx_put(nout);
        reg_outputs(tab, k, nout, NULL, NULL, scr);
        free(tab); free(scr); bfree(A); bfree(B); bfree(C);
    } else if (!strcmp(cmd, "trsmG")) { /* (code,T p-by-p,B p-by-w): left solve; code 0 U,T  1 L,N  2 U,N */
        int code = geti(prhs[1]);
        I p = (I)mxGetM(prhs[2]), w = (I)mxGetN(prhs[3]);
        plhs[0] = mxDuplicateArray(prhs[3]);
        dtrsm_("L", code == 1 ? "L" : "U", code == 0 ? "T" : "N", "N", &p, &w, &D1, mxGetDoubles(prhs[2]), &p,
               mxGetDoubles(plhs[0]), &p);
    } else if (!strcmp(cmd, "trsvT")) { /* (R,B p-by-w): dtrsv U,T,N column by column */
        I p = (I)mxGetM(prhs[1]), w = (I)mxGetN(prhs[2]);
        plhs[0] = mxDuplicateArray(prhs[2]);
        for (I j = 0; j < w; j++)
            dtrsv_("U", "T", "N", &p, mxGetDoubles(prhs[1]), &p, mxGetDoubles(plhs[0]) + j * p, &ONE);
    } else if (!strcmp(cmd, "trtrsT")) { /* (R,B p-by-w): dtrtrs U,T,N */
        I p = (I)mxGetM(prhs[1]), w = (I)mxGetN(prhs[2]), info = 0;
        plhs[0] = mxDuplicateArray(prhs[2]);
        dtrtrs_("U", "T", "N", &p, &w, mxGetDoubles(prhs[1]), &p, mxGetDoubles(plhs[0]), &p, &info);
    } else if (!strcmp(cmd, "rsolve_ref")) { /* (R,X n-by-p,recip): plain forward loops for X/R */
        I p = (I)mxGetM(prhs[1]), n = (I)mxGetM(prhs[2]);
        int recip = geti(prhs[3]);
        const double *R = mxGetDoubles(prhs[1]);
        plhs[0] = mxDuplicateArray(prhs[2]);
        double *E = mxGetDoubles(plhs[0]);
        for (I j = 0; j < p; j++) {
            for (I k = 0; k < j; k++) {
                volatile double r = R[k + j * p];
                for (I i = 0; i < n; i++) { volatile double t = E[i + k * n] * r; E[i + j * n] -= t; }
            }
            volatile double d = R[j + j * p], inv = 1.0 / d;
            for (I i = 0; i < n; i++) { if (recip) { volatile double t = E[i + j * n] * inv; E[i + j * n] = t; } else E[i + j * n] /= d; }
        }
    } else if (!strcmp(cmd, "lsolve_ref")) { /* (R,B p-by-w,recip): plain column sweep for R\B */
        I p = (I)mxGetM(prhs[1]), w = (I)mxGetN(prhs[2]);
        int recip = geti(prhs[3]);
        const double *R = mxGetDoubles(prhs[1]);
        plhs[0] = mxDuplicateArray(prhs[2]);
        double *B = mxGetDoubles(plhs[0]);
        for (I c = 0; c < w; c++)
            for (I k = p - 1; k >= 0; k--) {
                volatile double d = R[k + k * p], inv = 1.0 / d, xk;
                if (recip) xk = B[k + c * p] * inv; else xk = B[k + c * p] / d;
                B[k + c * p] = xk;
                for (I i = 0; i < k; i++) { volatile double t = xk * R[i + k * p]; B[i + c * p] -= t; }
            }
    } else if (!strcmp(cmd, "reg_tab")) { /* (kind,d1,d2,d3,d4,T nl-by-nl-by-nout): register trees read at MATLAB level */
        const mwSize *dims = mxGetDimensions(prhs[6]);
        int nl = (int)dims[0], nout = mxGetNumberOfDimensions(prhs[6]) >= 3 ? (int)dims[2] : 1;
        const double *Tm = mxGetDoubles(prhs[6]);
        size_t tot = (size_t)nout * nl * nl;
        uint8_t *tab = malloc(tot + 1), *scr = malloc((size_t)nl * nl + 1);
        for (size_t q = 0; q < tot; q++) tab[q] = clampcount(Tm[q]);
        idx_put(geti(prhs[1])); idx_put(geti(prhs[2])); idx_put(geti(prhs[3])); idx_put(geti(prhs[4])); idx_put(geti(prhs[5])); idx_put(nout);
        reg_outputs(tab, nl, nout, NULL, NULL, scr);
        free(tab); free(scr);
    } else if (!strcmp(cmd, "reg_save")) { /* (uniqueFile, indexFile) */
        char f1[1024], f2[1024];
        mxGetString(prhs[1], f1, sizeof f1); mxGetString(prhs[2], f2, sizeof f2);
        FILE *fp = fopen(f1, "wb");
        if (!fp) mexErrMsgIdAndTxt("kp1321:io", "cannot open registry file");
        for (size_t u = 0; u < u_count; u++) { fwrite(&u_n[u], sizeof(int32_t), 1, fp); fwrite(u_data + u_off[u], 1, (size_t)u_n[u] * (size_t)u_n[u], fp); }
        fclose(fp);
        fp = fopen(f2, "wb");
        if (!fp) mexErrMsgIdAndTxt("kp1321:io", "cannot open index file");
        fwrite(x_data, sizeof(int32_t), x_len, fp);
        fclose(fp);
        plhs[0] = mkmat(1, 2);
        mxGetDoubles(plhs[0])[0] = (double)u_count; mxGetDoubles(plhs[0])[1] = (double)x_len;
    } else {
        mexErrMsgIdAndTxt("kp1321:cmd", "unknown command");
    }
}
