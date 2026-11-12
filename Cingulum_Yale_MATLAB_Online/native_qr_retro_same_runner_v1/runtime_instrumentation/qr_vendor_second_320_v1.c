#define _GNU_SOURCE
#include <dlfcn.h>
#include <fcntl.h>
#include <inttypes.h>
#include <stdatomic.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

/* Original 320-case source-unseen vendor DGEMV dot diagnostic.
   Source outputs are revealed after frozen Rust predictions.
   Source-observed DIAGNOSTICS ONLY. Original MathWorks dgeqp3_ runs first,
   entirely unmodified. We then use its first reflector (A tail + tau1)
   plus the raw second column in fresh scratch buffers and call the original
   MathWorks vendor dlarf_, dgemv_ and ddot_. R12/h of the original QR are
   never modified. Source first-reflector values must never be used as
   inputs to a putatively independent Rust bitwise certification. */
#define CAP_M 128
#define CAP_EVENTS 2600
struct event {
 int64_t m,pivot_first,pivot_second,info;
 uint64_t x[CAP_M],first_A[CAP_M],second_A[CAP_M],tau2;
 uint64_t original_r12,vendor_dlarf_r12,vendor_dgemv_r12,vendor_ddot_r12;
 uint64_t gemv_dot,ddot_dot,tau1;
 int dlarf_present,dgemv_present,ddot_present;
};
static struct event events[CAP_EVENTS];
static _Atomic unsigned selected;
static _Atomic unsigned overflows;
static _Atomic unsigned long total_qr;

static int is_synthetic_qr(void *mp,void *np,void *ap,void *ldap,void *lworkp){
 if(!mp||!np||!ap||!ldap||!lworkp)return 0;
 int32_t lwork=0;memcpy(&lwork,lworkp,4);
 if(lwork<1)return 0;
 int32_t m,n,lda;
 memcpy(&m,mp,4);memcpy(&n,np,4);memcpy(&lda,ldap,4);
 if(n!=2||m<9||m>CAP_M||lda<m||lda>CAP_M)return 0;
 for(int i=0;i<m;i++){
  uint64_t bits;memcpy(&bits,(const char*)ap+8*(size_t)i,8);
  if(bits!=UINT64_C(0x3ff0000000000000))return 0;
 }
 return 1;
}
void dgeqp3_(void *mp,void *np,void *ap,void *ldap,void *jp,void *tau,void *work,void *lworkp,void *info){
 typedef void (*original_fn)(void*,void*,void*,void*,void*,void*,void*,void*,void*);
 typedef void (*dlarf_fn)(const char*,const int64_t*,const int64_t*,const double*,const int64_t*,const double*,double*,const int64_t*,double*);
 typedef void (*dgemv_fn)(const char*,const int64_t*,const int64_t*,const double*,const double*,const int64_t*,const double*,const int64_t*,const double*,double*,const int64_t*);
 typedef double (*ddot_fn)(const int64_t*,const double*,const int64_t*,const double*,const int64_t*);
 static original_fn original;
 if(!original){original=(original_fn)dlsym(RTLD_NEXT,"dgeqp3_");if(!original)_exit(127);}
 const int capture=is_synthetic_qr(mp,np,ap,ldap,lworkp);
 int64_t m=0,lda=0;double raw_x[CAP_M]={0};
 if(capture){
  memcpy(&m,mp,4);memcpy(&lda,ldap,4);
  for(int64_t i=0;i<m;i++)memcpy(&raw_x[i],(const char*)ap+8*(size_t)(lda+i),8);
 }
 original(mp,np,ap,ldap,jp,tau,work,lworkp,info);
 atomic_fetch_add_explicit(&total_qr,1,memory_order_relaxed);
 if(!capture)return;
 unsigned idx=atomic_fetch_add_explicit(&selected,1,memory_order_relaxed);
 if(idx>=CAP_EVENTS){atomic_fetch_add_explicit(&overflows,1,memory_order_relaxed);return;}
 struct event *e=&events[idx];e->m=m;
 uint64_t raw_pivot=0;memcpy(&raw_pivot,jp,8);
 if((raw_pivot>>32)!=0){
  e->pivot_first=(int64_t)(raw_pivot&UINT64_C(0xffffffff));
  e->pivot_second=(int64_t)(raw_pivot>>32);
 }else{
  e->pivot_first=(int64_t)raw_pivot;
  memcpy(&e->pivot_second,(const char*)jp+8,8);
 }
 memcpy(&e->info,info,4);
 for(int64_t i=0;i<m;i++)memcpy(&e->x[i],&raw_x[i],8);
 for(int64_t i=0;i<m;i++){
  memcpy(&e->first_A[i],(const char*)ap+8*(size_t)i,8);
  memcpy(&e->second_A[i],(const char*)ap+8*(size_t)(lda+i),8);
 }
 memcpy(&e->tau2,(const char*)tau+8,8);
 memcpy(&e->original_r12,(const char*)ap+8*(size_t)lda,8);
 memcpy(&e->tau1,tau,8);
 if(e->info!=0||(e->pivot_first!=1&&e->pivot_first!=2))return;
 double v[CAP_M]={0};double second[CAP_M]={0};
 v[0]=1.;
 for(int64_t i=1;i<m;i++)memcpy(&v[i],(const char*)ap+8*(size_t)i,8);
 if(e->pivot_first==1){for(int64_t i=0;i<m;i++)second[i]=raw_x[i];}
 else {for(int64_t i=0;i<m;i++)second[i]=1.;}
 const double tau1=*((const double*)tau);
 const int64_t one=1;
 dlarf_fn dlarf=(dlarf_fn)dlsym(RTLD_DEFAULT,"dlarf_");
 dgemv_fn dgemv=(dgemv_fn)dlsym(RTLD_DEFAULT,"dgemv_");
 ddot_fn ddot=(ddot_fn)dlsym(RTLD_DEFAULT,"ddot_");
 e->dlarf_present=dlarf!=NULL;e->dgemv_present=dgemv!=NULL;e->ddot_present=ddot!=NULL;
 if(dlarf){
  double scratch[CAP_M]={0};memcpy(scratch,second,(size_t)m*8);
  const char left='L';double buffer[1]={0};
  dlarf(&left,&m,&one,v,&one,&tau1,scratch,&m,buffer);
  memcpy(&e->vendor_dlarf_r12,&scratch[0],8);
 }
 if(dgemv){
  const char transpose='T';double scalar=0.,alpha=1.,beta=0.;
  dgemv(&transpose,&m,&one,&alpha,v,&m,second,&one,&beta,&scalar,&one);
  memcpy(&e->gemv_dot,&scalar,8);
  double cross=second[0]-tau1*scalar;
  memcpy(&e->vendor_dgemv_r12,&cross,8);
 }
 if(ddot){
  double scalar=ddot(&m,v,&one,second,&one);
  memcpy(&e->ddot_dot,&scalar,8);
  double cross=second[0]-tau1*scalar;
  memcpy(&e->vendor_ddot_r12,&cross,8);
 }
}
__attribute__((destructor))static void report(void){
 const char *path=getenv("QR_VENDOR_SECOND_LOG");if(!path||!*path)return;
 unsigned entries=atomic_load_explicit(&selected,memory_order_relaxed);
 if(!entries)return;
 int fd=open(path,O_WRONLY|O_CREAT|O_APPEND,0600);if(fd<0)return;
 char line[12000];
 for(unsigned k=0;k<entries&&k<CAP_EVENTS;k++){
  const struct event *e=&events[k];
  int o=snprintf(line,sizeof(line),"QR_VENDOR_SECOND_EVENT\tm=%" PRId64 "\tpivot=%" PRId64 ",%" PRId64 "\tinfo=%" PRId64 "\toriginal_r12=%016" PRIx64 "\tvendor_dlarf_r12=%016" PRIx64 "\tvendor_dgemv_r12=%016" PRIx64 "\tvendor_ddot_r12=%016" PRIx64 "\tgemv_dot=%016" PRIx64 "\tddot_dot=%016" PRIx64 "\ttau1=%016" PRIx64 "\tdlarf_present=%d\tdgemv_present=%d\tddot_present=%d\tX_HEX=",e->m,e->pivot_first,e->pivot_second,e->info,e->original_r12,e->vendor_dlarf_r12,e->vendor_dgemv_r12,e->vendor_ddot_r12,e->gemv_dot,e->ddot_dot,e->tau1,e->dlarf_present,e->dgemv_present,e->ddot_present);
  for(int64_t j=0;j<e->m;j++)o+=snprintf(line+o,sizeof(line)-(size_t)o,"%s%016" PRIx64,j?",":"",e->x[j]);
  o+=snprintf(line+o,sizeof(line)-(size_t)o,"\tFIRST_A_HEX=");
  for(int64_t j=0;j<e->m;j++)o+=snprintf(line+o,sizeof(line)-(size_t)o,"%s%016" PRIx64,j?",":"",e->first_A[j]);
  o+=snprintf(line+o,sizeof(line)-(size_t)o,"\tSECOND_A_HEX=");
  for(int64_t j=0;j<e->m;j++)o+=snprintf(line+o,sizeof(line)-(size_t)o,"%s%016" PRIx64,j?",":"",e->second_A[j]);
  o+=snprintf(line+o,sizeof(line)-(size_t)o,"\ttau2=%016" PRIx64,e->tau2);
  if(o>0&&o<(int)sizeof(line)-2){line[o++]='\n';ssize_t ignored=write(fd,line,(size_t)o);(void)ignored;}
 }
 int n=snprintf(line,sizeof(line),"QR_VENDOR_SECOND_SUMMARY\tselected=%u\toverflow=%u\ttotal_qr=%lu\n",entries,atomic_load(&overflows),atomic_load(&total_qr));
 if(n>0){ssize_t ignored=write(fd,line,(size_t)n);(void)ignored;}
 close(fd);
}
