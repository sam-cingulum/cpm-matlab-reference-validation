#include <stdio.h>
#include <stdint.h>
#include <string.h>
extern void dgeqp3_(int*,int*,double*,int*,int*,double*,double*,int*,int*);
int main(void){
 int m=29,n=2,lda=29,lwork=128,info=-1,jpvt[2]={0,0};
 double a[58],tau[2],work[128];
 for(int i=0;i<m;i++){a[i]=1.;a[m+i]=(double)((i*7)%17)/17.-0.3;}
 dgeqp3_(&m,&n,a,&lda,jpvt,tau,work,&lwork,&info);
 if(info){fprintf(stderr,"dgeqp3 error %d\n",info);return 1;}
 for(int i=0;i<58;i++){uint64_t bits;memcpy(&bits,&a[i],8);printf("%016llx\n",(unsigned long long)bits);}
 for(int i=0;i<2;i++){uint64_t bits;memcpy(&bits,&tau[i],8);printf("%016llx\n",(unsigned long long)bits);}
 printf("p=%d,%d\n",jpvt[0],jpvt[1]);
 return 0;
}
