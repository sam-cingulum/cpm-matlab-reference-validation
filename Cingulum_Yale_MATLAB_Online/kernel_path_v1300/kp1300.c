/* kp1300.c — V1300 original-only kernel path probe.
 *
 * A plain MEX gateway onto the BLAS/LAPACK that MathWorks ships and documents
 * for MEX use (-lmwblas -lmwlapack). It only calls public BLAS/LAPACK entry
 * points with chosen inputs and returns their outputs. It reads no Rust
 * forecast and no earlier MATLAB numerical output.
 *
 * Usage from MATLAB: out = kp1300(cmd, args...)
 */
#include "mex.h"
#include <math.h>
#include <stdint.h>
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

static const I ONE = 1;
static const double D1 = 1.0, D0 = 0.0;

/* 64-byte aligned buffer of n doubles starting `off` doubles past alignment. */
typedef struct { void *base; double *p; } Buf;
static Buf balloc(size_t n, int off) {
    Buf b;
    if (posix_memalign(&b.base, 64, (n + 16) * sizeof(double)) != 0)
        mexErrMsgIdAndTxt("kp1300:alloc", "allocation failed");
    memset(b.base, 0, (n + 16) * sizeof(double));
    b.p = (double *)b.base + off;
    return b;
}
static void bfree(Buf b) { free(b.base); }

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
        mexErrMsgIdAndTxt("kp1300:method", "unknown solve method");
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
        mexErrMsgIdAndTxt("kp1300:cmd", "first argument must be a command string");
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
    } else {
        mexErrMsgIdAndTxt("kp1300:cmd", "unknown command");
    }
}
