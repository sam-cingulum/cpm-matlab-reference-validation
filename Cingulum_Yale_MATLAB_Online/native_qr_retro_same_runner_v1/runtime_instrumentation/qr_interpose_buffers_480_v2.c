#define QR_INTERPOSE_OVERRIDE_DGEQP3 1
#include "qr_interpose_v1.c"
#include <string.h>

/* Source-unseen 320-case forensic QR boundary capture, precommitted Rust oracle.
   Original MATLAB source not altered and no numerical inputs overwritten.
    Captures raw binary64 matrix
   before/after the ORIGINAL MathWorks dgeqp3_ implementation, and LAPACK's
   output Householder TAU, JPVT and INFO without touching floating point.
   No per-call file I/O. Never use the trace as proof unless all MATLAB R and
   leverage outputs match the simultaneous uninstrumented control bitwise. */
#define CAP_M 128
#define CAP_EVENTS 4096
struct qr_event {
 unsigned long sequence;
 int32_t m,n,lda,lwork,info;
 int pivot_first,pivot_second,pivot_abi;
 uint64_t before[CAP_M*2], after[CAP_M*2],tau[2];
 uint64_t jpvt_raw;
};
static struct qr_event events[CAP_EVENTS];
static _Atomic unsigned n_events;
static _Atomic unsigned n_overflow;

static int capture_candidate(void *mp,void *np,void *ap,void *ldap,void *lworkp){
 if(!mp||!np||!ap||!ldap||!lworkp)return 0;
 int32_t m,n,lda,lwork;
 memcpy(&m,mp,4);memcpy(&n,np,4);memcpy(&lda,ldap,4);memcpy(&lwork,lworkp,4);
 if(n!=2 || m<9 || m>CAP_M || lda<m || lda>CAP_M || lwork<1)return 0;
 const unsigned char *a=ap;
 for(int i=0;i<m;i++){
  uint64_t bits;memcpy(&bits,a+(size_t)i*8,8);
  if(bits!=UINT64_C(0x3ff0000000000000))return 0;
 }
 return 1;
}
static void snap(uint64_t *to,const void *ap,int32_t m,int32_t lda){
 const unsigned char *a=ap;
 for(int j=0;j<2;j++)for(int i=0;i<m;i++)
  memcpy(&to[(size_t)j*m+i],a+((size_t)j*lda+i)*8,8);
}
void dgeqp3_(void *mp,void *np,void *ap,void *ldap,void *jp,void *tau,void *work,void *lworkp,void *info){
 typedef void (*fptr)(void*,void*,void*,void*,void*,void*,void*,void*,void*);
 static fptr real;
 if(!real)real=(fptr)resolve("dgeqp3_");
 atomic_fetch_add_explicit(&n_dgeqp3,1,memory_order_relaxed);
 struct qr_event *e=NULL;
 if(capture_candidate(mp,np,ap,ldap,lworkp)){
  unsigned idx=atomic_fetch_add_explicit(&n_events,1,memory_order_relaxed);
  if(idx<CAP_EVENTS){
   e=&events[idx];e->sequence=idx+1;
   memcpy(&e->m,mp,4);memcpy(&e->n,np,4);
   memcpy(&e->lda,ldap,4);memcpy(&e->lwork,lworkp,4);
   snap(e->before,ap,e->m,e->lda);
  }else atomic_fetch_add_explicit(&n_overflow,1,memory_order_relaxed);
 }
 real(mp,np,ap,ldap,jp,tau,work,lworkp,info);
 if(e){
  snap(e->after,ap,e->m,e->lda);
  memcpy(&e->tau[0],tau,8);memcpy(&e->tau[1],(const char*)tau+8,8);
  memcpy(&e->jpvt_raw,jp,8);
  unsigned p1=(unsigned)(e->jpvt_raw&UINT64_C(0xffffffff));
  unsigned p2=(unsigned)((e->jpvt_raw>>32)&UINT64_C(0xffffffff));
  e->pivot_first=(int)p1;
  if(p2==0 && (p1==1 || p1==2)){
    /* Original MathWorks Fortran LAPACK is ILP64: two 64-bit pivot slots.
       LP64 would store p2 in the high 32 bits of the first slot. */
    uint64_t v;memcpy(&v,(const char*)jp+8,8);
    e->pivot_second=(int)v;e->pivot_abi=64;
  }else{e->pivot_second=(int)p2;e->pivot_abi=32;}
  memcpy(&e->info,info,4);
 }
}
__attribute__((destructor)) static void report_buffers(void){
 const char *path=getenv("QR_CAPTURE_LOG");if(!path||!*path)return;
 int fd=open(path,O_WRONLY|O_CREAT|O_APPEND,0600);if(fd<0)return;
 unsigned total=atomic_load_explicit(&n_events,memory_order_relaxed);
 char buf[12000];
 for(unsigned k=0;k<total && k<CAP_EVENTS;k++){
  const struct qr_event *e=&events[k];
  if(!e->m)continue;
  int o=snprintf(buf,sizeof(buf),"QR_BUFFER_EVENT\tseq=%lu\tm=%d\tn=%d\tlda=%d\tlwork=%d\tinfo=%d\tjpvt_raw=%016llx\tjpvt_first=%d\tjpvt_second=%d\tjpvt_abi=%d\ttau=%016llx,%016llx\tA_IN=",e->sequence,e->m,e->n,e->lda,e->lwork,e->info,(unsigned long long)e->jpvt_raw,e->pivot_first,e->pivot_second,e->pivot_abi,(unsigned long long)e->tau[0],(unsigned long long)e->tau[1]);
  for(int j=0;j<e->m*2;j++)o+=snprintf(buf+o,sizeof(buf)-(size_t)o,"%s%016llx",j?",":"",(unsigned long long)e->before[j]);
  o+=snprintf(buf+o,sizeof(buf)-(size_t)o,"\tA_OUT=");
  for(int j=0;j<e->m*2;j++)o+=snprintf(buf+o,sizeof(buf)-(size_t)o,"%s%016llx",j?",":"",(unsigned long long)e->after[j]);
  if(o>0 && o<(int)sizeof(buf)-2){buf[o++]='\n';ssize_t ignored=write(fd,buf,(size_t)o);(void)ignored;}
 }
 int o=snprintf(buf,sizeof(buf),"QR_BUFFER_SUMMARY\tpid=%ld\tselected=%u\toverflow=%u\n",(long)getpid(),total,atomic_load(&n_overflow));
 if(o>0){ssize_t ignored=write(fd,buf,(size_t)o);(void)ignored;}
 close(fd);
}
