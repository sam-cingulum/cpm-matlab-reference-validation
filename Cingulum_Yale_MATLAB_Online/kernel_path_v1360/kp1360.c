/* kp1360.c — V1360 original-only dtrmm probe with a strided workspace.
 *
 * A plain MEX gateway onto the BLAS that MathWorks ships and documents for MEX use
 * (-lmwblas). It calls the public dtrmm with chosen inputs and returns its outputs. It reads
 * no Rust forecast and no earlier MATLAB numerical output.
 *
 *   W = kp1360('trmmld', uplo, trans, diag, M, Wfull, m)
 *       dtrmm('R', uplo, trans, diag, m, n, 1, M, n, Wfull, ldb) with M n-by-n and Wfull
 *       ldb-by-n (ldb = rows of Wfull >= m); returns the first m rows of Wfull after.
 */
#include "mex.h"
#include <stdlib.h>
#include <string.h>

typedef ptrdiff_t I;
extern void dtrmm_(const char *, const char *, const char *, const char *, const I *, const I *,
                   const double *, const double *, const I *, double *, const I *);
static const double D1 = 1.0;

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    char cmd[16], uplo[2], trans[2], diag[2];
    if (nrhs != 7) mexErrMsgIdAndTxt("kp1360:args", "seven arguments");
    mxGetString(prhs[0], cmd, sizeof cmd);
    if (strcmp(cmd, "trmmld")) mexErrMsgIdAndTxt("kp1360:cmd", "unknown command");
    mxGetString(prhs[1], uplo, 2); mxGetString(prhs[2], trans, 2); mxGetString(prhs[3], diag, 2);
    I n = (I)mxGetM(prhs[4]), ldb = (I)mxGetM(prhs[5]), m = (I)mxGetScalar(prhs[6]);
    if ((I)mxGetN(prhs[4]) != n || (I)mxGetN(prhs[5]) != n || m < 1 || m > ldb)
        mexErrMsgIdAndTxt("kp1360:args", "shapes");
    void *mb = NULL, *wb = NULL;
    if (posix_memalign(&mb, 64, (size_t)(n * n) * 8) || posix_memalign(&wb, 64, (size_t)(ldb * n) * 8))
        mexErrMsgIdAndTxt("kp1360:alloc", "allocation failed");
    double *M = mb, *W = wb;
    memcpy(M, mxGetDoubles(prhs[4]), (size_t)(n * n) * 8);
    memcpy(W, mxGetDoubles(prhs[5]), (size_t)(ldb * n) * 8);
    dtrmm_("R", uplo, trans, diag, &m, &n, &D1, M, &n, W, &ldb);
    plhs[0] = mxCreateDoubleMatrix((size_t)m, (size_t)n, mxREAL);
    double *o = mxGetDoubles(plhs[0]);
    for (I j = 0; j < n; j++) memcpy(o + j * m, W + j * ldb, (size_t)m * 8);
    free(mb); free(wb);
    (void)nlhs;
}
