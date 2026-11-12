#define _GNU_SOURCE
#include <dlfcn.h>
#include <fcntl.h>
#include <stdatomic.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

/* Original MathWorks DGEMV introspection, source-unseen real-binary64 vectors.
   Calls the unchanged original DGEQP3 first. On its first return, only
   synthetic scratch buffers are passed to original MathWorks DGEMV; never
   alter original QR, MATLAB-owned x/y or R/h. Source-blind pure Rust forecasts
   MUST be independently frozen/pushed before any of these calls run. */
#define MAX_SAMPLES 512
#define MAX_N 128
struct sample{char id[128];uint16_t n;uint64_t vendor_bits;uint8_t repeat_exact,ran;};
static struct sample samples[MAX_SAMPLES];
static _Atomic int started;
static unsigned count,failures,source_repeat_mismatches;
static _Atomic unsigned long orig_qr_calls;
static void load_original_vendor_scratch_cases(void){
 const char *source=getenv("QR_VENDOR_NEW_INPUT_TSV");if(!source||!*source)return;
 FILE *f=fopen(source,"r");if(!f){failures++;return;}
 typedef void (*gemv_fn)(const char*,const int64_t*,const int64_t*,const double*,const double*,const int64_t*,const double*,const int64_t*,const double*,double*,const int64_t*);
 gemv_fn gemv=(gemv_fn)dlsym(RTLD_DEFAULT,"dgemv_");if(!gemv){failures++;fclose(f);return;}
 char line[16384];
 while(fgets(line,sizeof(line),f)){
  if(count>=MAX_SAMPLES){failures++;break;}
  char *save=NULL;
  char *id=strtok_r(line,"\t\n",&save);
  char *nstr=strtok_r(NULL,"\t\n",&save);
  char *vstr=strtok_r(NULL,"\t\n",&save);
  char *xstr=strtok_r(NULL,"\t\n",&save);
  if(!id||!nstr||!vstr||!xstr||strlen(id)>=sizeof(samples[count].id)){failures++;continue;}
  char *end=NULL;long nn=strtol(nstr,&end,10);
  if(*end||nn<16||nn>MAX_N){failures++;continue;}
  int64_t n=(int64_t)nn;
  double v[MAX_N]={0},x[MAX_N]={0};
  char *vsp=NULL,*xsp=NULL;char *vt=strtok_r(vstr,",",&vsp),*xt=strtok_r(xstr,",",&xsp);
  int good=1;
  for(int64_t j=0;j<n;j++){
   if(!vt||!xt||strlen(vt)!=16||strlen(xt)!=16){good=0;break;}
   char *ve=NULL,*xe=NULL;
   uint64_t vb=strtoull(vt,&ve,16),xb=strtoull(xt,&xe,16);
   if(*ve||*xe){good=0;break;}
   memcpy(&v[j],&vb,8);memcpy(&x[j],&xb,8);
   vt=strtok_r(NULL,",",&vsp);xt=strtok_r(NULL,",",&xsp);
  }
  if(!good||vt||xt){failures++;continue;}
  const char trans='T';const int64_t one=1;const double alpha=1.,beta=0.;
  double result=0.,repeat=0.;
  gemv(&trans,&n,&one,&alpha,v,&n,x,&one,&beta,&result,&one);
  gemv(&trans,&n,&one,&alpha,v,&n,x,&one,&beta,&repeat,&one);
  uint64_t got,again;memcpy(&got,&result,8);memcpy(&again,&repeat,8);
  if(got!=again)source_repeat_mismatches++;
  struct sample *s=&samples[count];strcpy(s->id,id);s->n=(uint16_t)n;s->vendor_bits=got;
  s->repeat_exact=(uint8_t)(got==again);s->ran=1;count++;
 }
 fclose(f);
}
void dgeqp3_(void *m,void *n,void *a,void *lda,void *pivot,void *tau,void *work,void *lwork,void *info){
 typedef void(*fptr)(void*,void*,void*,void*,void*,void*,void*,void*,void*);
 static fptr fn;
 if(!fn){fn=(fptr)dlsym(RTLD_NEXT,"dgeqp3_");if(!fn)_exit(127);}
 fn(m,n,a,lda,pivot,tau,work,lwork,info);
 atomic_fetch_add_explicit(&orig_qr_calls,1,memory_order_relaxed);
 int expected=0;
 if(atomic_compare_exchange_strong_explicit(&started,&expected,1,memory_order_relaxed,memory_order_relaxed))load_original_vendor_scratch_cases();
}
__attribute__((destructor))static void report(void){
 const char *path=getenv("QR_VENDOR_NEW_DOT_RESULTS");if(!path||!*path||!count)return;
 int fd=open(path,O_WRONLY|O_CREAT|O_TRUNC,0600);if(fd<0)return;
 char line[512];
 for(unsigned i=0;i<count;i++){
  const struct sample *s=&samples[i];
  int n=snprintf(line,sizeof(line),"QR_VENDOR_FROZEN_EVENT\tid=%s\tn=%u\tvendor_dot=%016llx\trepeat=%u\n",s->id,s->n,(unsigned long long)s->vendor_bits,(unsigned)s->repeat_exact);
  if(n>0&&(size_t)n<sizeof(line)){ssize_t ignored=write(fd,line,(size_t)n);(void)ignored;}
 }
 int n=snprintf(line,sizeof(line),"QR_VENDOR_FROZEN_SUMMARY\tcount=%u\tfailures=%u\trepeat_mismatches=%u\toriginal_qr_calls=%lu\n",count,failures,source_repeat_mismatches,atomic_load(&orig_qr_calls));
 if(n>0&&(size_t)n<sizeof(line)){ssize_t ignored=write(fd,line,(size_t)n);(void)ignored;}
 close(fd);
}
