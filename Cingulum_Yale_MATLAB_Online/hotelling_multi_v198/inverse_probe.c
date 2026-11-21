/* Reference-only comparison of the documented lower symmetric, general LU and
   positive-definite LAPACK factorization/inversion pairs on the original C. */
#include "mex.h"
#include "lapack.h"
#include <string.h>

static void check(ptrdiff_t info,const char *name) {
    if (info!=0) mexErrMsgIdAndTxt("CPM:LapackFailure","%s returned %d",name,(int)info);
}

void mexFunction(int nlhs,mxArray *out[],int nrhs,const mxArray *in[]) {
    if(nrhs!=1 || nlhs!=5 || !mxIsDouble(in[0]) || mxIsComplex(in[0]) ||
       mxGetM(in[0])!=mxGetN(in[0]) || mxGetM(in[0])<1 || mxGetM(in[0])>6)
        mexErrMsgIdAndTxt("CPM:Geometry","Expected a one- to six-dimensional covariance.");
    ptrdiff_t n=(ptrdiff_t)mxGetM(in[0]), lwork=512,info=0,ipiv[6];
    char lower='L'; double work[512];
    for(int j=0;j<4;++j) out[j]=mxDuplicateArray(in[0]);
    out[4]=mxCreateDoubleMatrix(n,1,mxREAL);
    double *sy=mxGetDoubles(out[0]),*lu=mxGetDoubles(out[1]),*ch=mxGetDoubles(out[2]);
    dsytrf(&lower,&n,sy,&n,ipiv,work,&lwork,&info);check(info,"dsytrf");
    memcpy(mxGetDoubles(out[3]),sy,sizeof(double)*n*n);
    for(ptrdiff_t i=0;i<n;++i) mxGetDoubles(out[4])[i]=(double)ipiv[i];
    dsytri(&lower,&n,sy,&n,ipiv,work,&info);check(info,"dsytri");
    dgetrf(&n,&n,lu,&n,ipiv,&info);check(info,"dgetrf");
    dgetri(&n,lu,&n,ipiv,work,&lwork,&info);check(info,"dgetri");
    dpotrf(&lower,&n,ch,&n,&info);check(info,"dpotrf");
    dpotri(&lower,&n,ch,&n,&info);check(info,"dpotri");
    for(ptrdiff_t j=0;j<n;++j) for(ptrdiff_t i=0;i<j;++i) {
        sy[i+j*n]=sy[j+i*n];ch[i+j*n]=ch[j+i*n];
    }
}
