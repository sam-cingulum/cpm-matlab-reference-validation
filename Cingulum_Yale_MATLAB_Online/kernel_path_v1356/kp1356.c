/* kp1356.c — V1356 original-only dormqr corner probe (block sizes 16 and 32, column panels).
 * A plain MEX gateway onto MathWorks' documented BLAS/LAPACK (-lmwblas -lmwlapack). It calls
 * public LAPACK entry points with chosen inputs and returns their outputs. It reads no Rust
 * forecast and no earlier MATLAB numerical output.
 *   Z = kp1356('solve', X, B, mode, nb, P)
 *   mode 0: dgeqp3 -> dormqr('L','T') (optimal lwork) -> dtrtrs
 *   mode 1: dgeqp3 -> dorm2r -> dtrtrs
 *   mode 2: dgeqp3 -> blocked dlarft + dlarfb with block size nb on all of C -> dtrtrs
 *   mode 4: as mode 2, but C is cut into column panels of P columns (the last one holds what
 *           is left) and each panel gets the whole blocked pass on its own
 *   mode 5: dgeqp3 -> dormqr (optimal lwork) on each column panel of P columns -> dtrtrs
 *   S = kp1356('stage', X, B, nb)
 *   dgeqp3, then dlarft and one dlarfb for the first block of nb reflectors on all of C.
 *   S = [tau (n); packed QR (m*n); jpvt (n); T (nb*nb, ld nb); C after that dlarfb (m*w)]
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
static void *xm(size_t b) { void *p = calloc(b ? b : 1, 1); if (!p) mexErrMsgIdAndTxt("kp1356:alloc", "alloc"); return p; }

/* blocked pass with block size nb over the m-by-w matrix C (leading dimension m) */
static void blocked(I m, I n, I w, I nb, const double *A, const double *tau, double *C) {
    double *t = xm((size_t)(nb * nb) * 8 + 8), *wk = xm((size_t)(w * nb) * 8 + 8);
    for (I i0 = 0; i0 < n; i0 += nb) {
        I ib = (n - i0 < nb) ? n - i0 : nb, mm = m - i0;
        memset(t, 0, (size_t)(nb * nb) * 8);
        dlarft_("F", "C", &mm, &ib, &A[i0 + i0 * m], &m, &tau[i0], t, &ib);
        dlarfb_("L", "T", "F", "C", &mm, &w, &ib, &A[i0 + i0 * m], &m, t, &ib, &C[i0], &m, wk, &w);
    }
    free(t); free(wk);
}

static void ormqr_full(I m, I n, I w, const double *A, const double *tau, double *C) {
    I lw = -1, info = 0; double q = 0, *wk;
    dormqr_("L", "T", &m, &w, &n, A, &m, tau, C, &m, &q, &lw, &info); lw = (I)q;
    wk = xm((size_t)(lw > 1 ? lw : 1) * 8 + 64 * 65 * 8);
    dormqr_("L", "T", &m, &w, &n, A, &m, tau, C, &m, wk, &lw, &info); free(wk);
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    char cmd[16]; (void)nlhs;
    if (nrhs < 1 || mxGetString(prhs[0], cmd, sizeof cmd)) mexErrMsgIdAndTxt("kp1356:cmd", "command");
    int solve = !strcmp(cmd, "solve"), stage = !strcmp(cmd, "stage");
    if (!solve && !stage) mexErrMsgIdAndTxt("kp1356:cmd", "unknown command");
    I m = (I)mxGetM(prhs[1]), n = (I)mxGetN(prhs[1]), w = (I)mxGetN(prhs[2]), info = 0, lw = -1;
    int mode = solve ? (int)mxGetScalar(prhs[3]) : 2;
    I nb = (I)mxGetScalar(prhs[solve ? 4 : 3]);
    I P = solve ? (I)mxGetScalar(prhs[5]) : 0;
    double *A = xm((size_t)(m * n) * 8), *tau = xm((size_t)n * 8 + 8), *C = xm((size_t)(m * w) * 8), q = 0, *wk;
    I *jp = xm((size_t)n * sizeof(I));
    memcpy(A, mxGetDoubles(prhs[1]), (size_t)(m * n) * 8); memcpy(C, mxGetDoubles(prhs[2]), (size_t)(m * w) * 8);
    dgeqp3_(&m, &n, A, &m, jp, tau, &q, &lw, &info); lw = (I)q; wk = xm((size_t)(lw > 1 ? lw : 1) * 8);
    dgeqp3_(&m, &n, A, &m, jp, tau, wk, &lw, &info); free(wk);
    if (stage) {
        I ib = n < nb ? n : nb;
        double *t = xm((size_t)(nb * nb) * 8 + 8), *wk2 = xm((size_t)(w * nb) * 8 + 8);
        dlarft_("F", "C", &m, &ib, A, &m, tau, t, &nb);
        dlarfb_("L", "T", "F", "C", &m, &w, &ib, A, &m, t, &nb, C, &m, wk2, &w);
        size_t total = (size_t)(n + m * n + n + nb * nb + m * w);
        plhs[0] = mxCreateDoubleMatrix(total, 1, mxREAL);
        double *S = mxGetDoubles(plhs[0]); size_t at = 0;
        memcpy(S + at, tau, (size_t)n * 8); at += (size_t)n;
        memcpy(S + at, A, (size_t)(m * n) * 8); at += (size_t)(m * n);
        for (I i = 0; i < n; i++) S[at++] = (double)jp[i];
        memcpy(S + at, t, (size_t)(nb * nb) * 8); at += (size_t)(nb * nb);
        memcpy(S + at, C, (size_t)(m * w) * 8);
        free(t); free(wk2); free(A); free(tau); free(C); free(jp);
        return;
    }
    if (mode == 0) {
        ormqr_full(m, n, w, A, tau, C);
    } else if (mode == 1) {
        wk = xm((size_t)w * 8 + 8); dorm2r_("L", "T", &m, &w, &n, A, &m, tau, C, &m, wk, &info); free(wk);
    } else if (mode == 2) {
        blocked(m, n, w, nb, A, tau, C);
    } else if (mode == 4 || mode == 5) {
        if (P < 1) mexErrMsgIdAndTxt("kp1356:panel", "panel width");
        for (I j0 = 0; j0 < w; j0 += P) {
            I pw = (w - j0 < P) ? w - j0 : P;
            if (mode == 4) blocked(m, n, pw, nb, A, tau, &C[j0 * m]);
            else ormqr_full(m, n, pw, A, tau, &C[j0 * m]);
        }
    } else {
        mexErrMsgIdAndTxt("kp1356:mode", "unknown mode");
    }
    dtrtrs_("U", "N", "N", &n, &w, A, &m, C, &m, &info);
    plhs[0] = mxCreateDoubleMatrix((size_t)n, (size_t)w, mxREAL);
    double *Z = mxGetDoubles(plhs[0]);
    for (I j = 0; j < w; j++) for (I i = 0; i < n; i++) Z[(jp[i] - 1) + j * n] = C[i + j * m];
    free(A); free(tau); free(C); free(jp);
}
