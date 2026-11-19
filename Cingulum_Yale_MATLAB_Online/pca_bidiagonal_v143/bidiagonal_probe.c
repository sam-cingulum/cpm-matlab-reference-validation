/* Diagnostic using the public LAPACK interface. Only runs in the original
   MATLAB reference environment. The Rust implementation receives raw X. */
#include "mex.h"
#include "lapack.h"
#include <string.h>

static void check_info(ptrdiff_t info, const char *routine) {
    if (info != 0)
        mexErrMsgIdAndTxt("CPM:LapackFailure", "%s returned %d", routine, (int)info);
}

void mexFunction(int nlhs, mxArray *out[], int nrhs, const mxArray *in[]) {
    if (nrhs != 1 || nlhs != 7 || !mxIsDouble(in[0]) || mxIsComplex(in[0]) ||
        mxGetM(in[0]) != mxGetN(in[0]) || mxGetM(in[0]) < 3 || mxGetM(in[0]) > 6)
        mexErrMsgIdAndTxt("CPM:Geometry", "Expected one real square matrix of width 3 through 6.");
    ptrdiff_t n = (ptrdiff_t)mxGetM(in[0]), work_size = 512, info = 0, zero = 0, one = 1;
    double work[512], d[6], e[6], unused = 0.;
    const size_t matrix_bytes = sizeof(double)*n*n;
    for (int j = 0; j < 4; ++j)
        out[j] = mxCreateDoubleMatrix(n - (j == 1), 1, mxREAL);
    for (int j = 4; j < 7; ++j)
        out[j] = mxCreateDoubleMatrix(n, n, mxREAL);
    double *diag = mxGetDoubles(out[0]), *off = mxGetDoubles(out[1]);
    double *tq = mxGetDoubles(out[2]), *tp = mxGetDoubles(out[3]), *pt = mxGetDoubles(out[4]);
    memcpy(pt,mxGetDoubles(in[0]),matrix_bytes);
    dgebrd(&n,&n,pt,&n,diag,off,tq,tp,work,&work_size,&info);
    check_info(info,"dgebrd");
    char side = 'P', upper = 'U';
    dorgbr(&side,&n,&n,&n,pt,&n,tp,work,&work_size,&info);
    check_info(info,"dorgbr");
    for (int j = 5; j < 7; ++j) {
        double *vt = mxGetDoubles(out[j]);
        if (j == 5) memcpy(vt,pt,matrix_bytes);
        else for (ptrdiff_t i = 0; i < n; ++i) vt[i + n*i] = 1.;
        memcpy(d,diag,n*sizeof(double));
        memcpy(e,off,(n-1)*sizeof(double));
        dbdsqr(&upper,&n,&n,&zero,&zero,d,e,vt,&n,&unused,&one,&unused,&one,work,&info);
        check_info(info,"dbdsqr");
    }
}
