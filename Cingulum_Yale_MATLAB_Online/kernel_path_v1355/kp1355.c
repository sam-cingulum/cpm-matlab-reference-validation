/* kp1355.c — V1355 original-only dormqr width-dispatch probe.
 * A plain MEX gateway onto MathWorks' documented BLAS/LAPACK (-lmwblas -lmwlapack). It calls
 * public LAPACK entry points with chosen inputs and returns their outputs. It reads no Rust
 * forecast and no earlier MATLAB numerical output.
 *   Z = kp1355('solve', X, B, mode, nb)
 *   mode 0: dgeqp3 -> dormqr('L','T') (optimal lwork) -> dtrtrs
 *   mode 1: dgeqp3 -> dorm2r -> dtrtrs
 *   mode 2: dgeqp3 -> blocked dlarft + dlarfb with block size nb -> dtrtrs
 *   mode 3: dgeqp3 -> dormqr with lwork = w * nb (MKL may lower its block size) -> dtrtrs
 */
#include "mex.h"
#include <stdlib.h>
#include <string.h>
typedef ptrdiff_t I;
extern void dgeqp3_(const I *, const I *, double *, const I *, I *, double *, double *, const I *, I *);
extern void dormqr_(const char *, const char *, const I *, const I *, const I *, const double *, const I *,
                    const double *, double *, const I *, double *, const I *, I *);
extern void dorm2r_(const char *, const char *, const I *, const I *, const I *, const double *, const I *,
                    const double *, double *, const I *, double *, I *);
extern void dlarft_(const char *, const char *, const I *, const I *, const double *, const I *,
                    const double *, double *, const I *);
extern void dlarfb_(const char *, const char *, const char *, const char *, const I *, const I *, const I *,
                    const double *, const I *, const double *, const I *, double *, const I *, double *, const I *);
extern void dtrtrs_(const char *, const char *, const char *, const I *, const I *, const double *, const I *,
                    double *, const I *, I *);
static void *xm(size_t b) { void *p = calloc(b ? b : 1, 1); if (!p) mexErrMsgIdAndTxt("kp1355:alloc", "alloc"); return p; }
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    char cmd[16]; (void)nlhs;
    if (nrhs < 1 || mxGetString(prhs[0], cmd, sizeof cmd)) mexErrMsgIdAndTxt("kp1355:cmd", "command");
    if (strcmp(cmd, "solve")) mexErrMsgIdAndTxt("kp1355:cmd", "unknown command");
    I m = (I)mxGetM(prhs[1]), n = (I)mxGetN(prhs[1]), w = (I)mxGetN(prhs[2]), info = 0, lw = -1;
    int mode = (int)mxGetScalar(prhs[3]); I nb = (I)mxGetScalar(prhs[4]);
    double *A = xm((size_t)(m * n) * 8), *tau = xm((size_t)n * 8 + 8), *C = xm((size_t)(m * w) * 8), q = 0, *wk;
    I *jp = xm((size_t)n * sizeof(I));
    memcpy(A, mxGetDoubles(prhs[1]), (size_t)(m * n) * 8); memcpy(C, mxGetDoubles(prhs[2]), (size_t)(m * w) * 8);
    dgeqp3_(&m, &n, A, &m, jp, tau, &q, &lw, &info); lw = (I)q; wk = xm((size_t)(lw > 1 ? lw : 1) * 8);
    dgeqp3_(&m, &n, A, &m, jp, tau, wk, &lw, &info); free(wk);
    if (mode == 0 || mode == 3) {
        if (mode == 0) { lw = -1; dormqr_("L", "T", &m, &w, &n, A, &m, tau, C, &m, &q, &lw, &info); lw = (I)q; }
        else lw = w * nb;
        wk = xm((size_t)(lw > 1 ? lw : 1) * 8 + 64 * 65 * 8);
        dormqr_("L", "T", &m, &w, &n, A, &m, tau, C, &m, wk, &lw, &info); free(wk);
    } else if (mode == 1) {
        wk = xm((size_t)w * 8 + 8); dorm2r_("L", "T", &m, &w, &n, A, &m, tau, C, &m, wk, &info); free(wk);
    } else {
        double *t = xm((size_t)(nb * nb) * 8 + 8); wk = xm((size_t)(w * nb) * 8 + 8);
        for (I i0 = 0; i0 < n; i0 += nb) {
            I ib = (n - i0 < nb) ? n - i0 : nb, mm = m - i0;
            memset(t, 0, (size_t)(nb * nb) * 8);
            dlarft_("F", "C", &mm, &ib, &A[i0 + i0 * m], &m, &tau[i0], t, &ib);
            dlarfb_("L", "T", "F", "C", &mm, &w, &ib, &A[i0 + i0 * m], &m, t, &ib, &C[i0], &m, wk, &w);
        }
        free(t); free(wk);
    }
    dtrtrs_("U", "N", "N", &n, &w, A, &m, C, &m, &info);
    plhs[0] = mxCreateDoubleMatrix((size_t)n, (size_t)w, mxREAL);
    double *Z = mxGetDoubles(plhs[0]);
    for (I j = 0; j < w; j++) for (I i = 0; i < n; i++) Z[(jp[i] - 1) + j * n] = C[i + j * m];
    free(A); free(tau); free(C); free(jp);
}
