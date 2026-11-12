#include <stdio.h>
#include <stdint.h>
#include <string.h>
extern void dgeqrf_(int*,int*,double*,int*,double*,double*,int*,int*);
int main(void){
 int m=4,n=2,lda=4,lwork=64,info=-1;
 double a[]={1.,1.,1.,1., 0.17, 0.23, -0.31, 0.51},tau[2],work[64];
 dgeqrf_(&m,&n,a,&lda,tau,work,&lwork,&info);
 if(info){fprintf(stderr,"dgeqrf error %d\n",info);return 1;}
 for(int i=0;i<8;i++){uint64_t bits;memcpy(&bits,&a[i],8);printf("%016llx\n",(unsigned long long)bits);}
 for(int i=0;i<2;i++){uint64_t bits;memcpy(&bits,&tau[i],8);printf("%016llx\n",(unsigned long long)bits);}
 return 0;
}
