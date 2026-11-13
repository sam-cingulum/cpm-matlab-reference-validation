#define _GNU_SOURCE
#include <dlfcn.h>
#include <fcntl.h>
#include <stdatomic.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
/* Passive source-revealed six-case MathWorks weighted backslash study.
 * All function pointers forwarded verbatim, and no float calculations or
 * file I/O on hot paths. Only no-character Fortran-ABI routines wrapped.
 * Always compare an uninstrumented MATLAB result bytewise, and FAIL if
 * any numerical difference is introduced by LD_PRELOAD instrumentation.
 */
static void *next(const char *name) {
 void *p=dlsym(RTLD_NEXT,name);
 if(!p) {ssize_t ignored=write(2,"WLS_TRACE_SYMBOL_NOT_FOUND\n",27);(void)ignored;_exit(127);}
 return p;
}
#define DECLARE_COUNTER(name) static _Atomic unsigned long cnt_##name;
DECLARE_COUNTER(dgeqp3_)
DECLARE_COUNTER(dgeqrf_)
DECLARE_COUNTER(dgeqr2_)
DECLARE_COUNTER(dorgqr_)
DECLARE_COUNTER(dlarfg_)
DECLARE_COUNTER(dgelsy_)
DECLARE_COUNTER(dgelsd_)
DECLARE_COUNTER(dgesv_)
DECLARE_COUNTER(dscal_)
DECLARE_COUNTER(daxpy_)
DECLARE_COUNTER(ddot_)
DECLARE_COUNTER(dnrm2_)
DECLARE_COUNTER(dormqr_)
DECLARE_COUNTER(dtrtrs_)
DECLARE_COUNTER(dtrsv_)
DECLARE_COUNTER(dtrsm_)
/* In-memory snapshots from only small disclosed synthetic weighted solvers.
 * No filesystem activity within the original vendor numerics. Capturing
 * bytes does not alter FPU state, input arrays, or their arithmetic. */
#define MAX_STAGES 128
#define MAX_SAMPLES 25
struct rhs_event {
 char routine[8], side, trans, diag;
 int32_t m,n,k,info;
 uint64_t before[MAX_SAMPLES],after[MAX_SAMPLES],a[4];
};
static struct rhs_event rhs_events[MAX_STAGES];
static _Atomic unsigned rhs_count;
static unsigned rhs_overflow;
static struct rhs_event *event_new(const char *routine) {
 unsigned slot=atomic_fetch_add(&rhs_count,1);
 if(slot>=MAX_STAGES){rhs_overflow++;return NULL;}
 struct rhs_event *v=&rhs_events[slot];
 strncpy(v->routine,routine,sizeof(v->routine)-1);
 return v;
}
static int32_t lo32(const void *p){int32_t x=0;if(p)memcpy(&x,p,sizeof x);return x;}
static void save_numbers(uint64_t *dst,const void *src,unsigned n){
 if(!src)return;
 const unsigned char *p=src;
 for(unsigned i=0;i<n;i++)memcpy(&dst[i],p+8u*i,8);
}
#define WRAP_3(name) \
void name(void *a,void *b,void *c){ \
 typedef void (*fp)(void*,void*,void*);static fp original;if(!original)original=(fp)next(#name); \
 atomic_fetch_add(&cnt_##name,1);original(a,b,c);}
#define WRAP_4(name) \
void name(void *a,void *b,void *c,void *d){ \
 typedef void (*fp)(void*,void*,void*,void*);static fp original;if(!original)original=(fp)next(#name); \
 atomic_fetch_add(&cnt_##name,1);original(a,b,c,d);}
#define WRAP_5(name) \
void name(void *a,void *b,void *c,void *d,void *e){ \
 typedef void (*fp)(void*,void*,void*,void*,void*);static fp original;if(!original)original=(fp)next(#name); \
 atomic_fetch_add(&cnt_##name,1);original(a,b,c,d,e);}
#define WRAP_6(name) \
void name(void *a,void *b,void *c,void *d,void *e,void *f){ \
 typedef void (*fp)(void*,void*,void*,void*,void*,void*);static fp original;if(!original)original=(fp)next(#name); \
 atomic_fetch_add(&cnt_##name,1);original(a,b,c,d,e,f);}
#define WRAP_7(name) \
void name(void *a,void *b,void *c,void *d,void *e,void *f,void *g){ \
 typedef void (*fp)(void*,void*,void*,void*,void*,void*,void*);static fp original;if(!original)original=(fp)next(#name); \
 atomic_fetch_add(&cnt_##name,1);original(a,b,c,d,e,f,g);}
#define WRAP_8(name) \
void name(void *a,void *b,void *c,void *d,void *e,void *f,void *g,void *h){ \
 typedef void (*fp)(void*,void*,void*,void*,void*,void*,void*,void*);static fp original;if(!original)original=(fp)next(#name); \
 atomic_fetch_add(&cnt_##name,1);original(a,b,c,d,e,f,g,h);}
#define WRAP_9(name) \
void name(void *a,void *b,void *c,void *d,void *e,void *f,void *g,void *h,void *i){ \
 typedef void (*fp)(void*,void*,void*,void*,void*,void*,void*,void*,void*);static fp original;if(!original)original=(fp)next(#name); \
 atomic_fetch_add(&cnt_##name,1);original(a,b,c,d,e,f,g,h,i);}
#define WRAP_13(name) \
void name(void *a,void *b,void *c,void *d,void *e,void *f,void *g,void *h,void *i,void *j,void *k,void *l,void *m){ \
 typedef void (*fp)(void*,void*,void*,void*,void*,void*,void*,void*,void*,void*,void*,void*,void*);static fp original;if(!original)original=(fp)next(#name); \
 atomic_fetch_add(&cnt_##name,1);original(a,b,c,d,e,f,g,h,i,j,k,l,m);}
#define WRAP_14(name) \
void name(void *a,void *b,void *c,void *d,void *e,void *f,void *g,void *h,void *i,void *j,void *k,void *l,void *m,void *n){ \
 typedef void (*fp)(void*,void*,void*,void*,void*,void*,void*,void*,void*,void*,void*,void*,void*,void*);static fp original;if(!original)original=(fp)next(#name); \
 atomic_fetch_add(&cnt_##name,1);original(a,b,c,d,e,f,g,h,i,j,k,l,m,n);}
WRAP_9(dgeqp3_)
WRAP_8(dgeqrf_)
WRAP_7(dgeqr2_)
WRAP_9(dorgqr_)
WRAP_5(dlarfg_)
WRAP_13(dgelsy_)
WRAP_14(dgelsd_)
WRAP_8(dgesv_)
WRAP_4(dscal_)
WRAP_6(daxpy_)
/* CHARACTER*1 Fortran LAPACK/BLAS ABI: forward the two to four trailing
 * hidden char-length words as well as every original pointer. Instrumented
 * output must remain BYTE-IDENTICAL to the uninstru­mented control. */
void dormqr_(void*a,void*b,void*c,void*d,void*e,void*f,void*g,void*h,void*i,void*j,void*k,void*l,void*m,size_t s,size_t t){
 typedef void(*fp)(void*,void*,void*,void*,void*,void*,void*,void*,void*,void*,void*,void*,void*,size_t,size_t);
 static fp original;if(!original)original=(fp)next("dormqr_");
 atomic_fetch_add(&cnt_dormqr_,1);
 int32_t rows=lo32(c),columns=lo32(d),reflectors=lo32(e),ldc=lo32(j),work=lo32(l);
 struct rhs_event *event=NULL;
 if(rows>=9&&rows<=MAX_SAMPLES&&columns==1&&reflectors==2&&ldc>=rows&&work>=1){
   event=event_new("dormqr");
   if(event){
     event->side=a?*(char*)a:0;event->trans=b?*(char*)b:0;
     event->m=rows;event->n=columns;event->k=reflectors;
     save_numbers(event->before,i,(unsigned)rows);
   }
 }
 original(a,b,c,d,e,f,g,h,i,j,k,l,m,s,t);
 if(event){
   save_numbers(event->after,i,(unsigned)rows);
   event->info=lo32(m);
 }
}
void dtrtrs_(void*a,void*b,void*c,void*d,void*e,void*f,void*g,void*h,void*i,void*j,size_t s,size_t t,size_t u){
 typedef void(*fp)(void*,void*,void*,void*,void*,void*,void*,void*,void*,void*,size_t,size_t,size_t);
 static fp original;if(!original)original=(fp)next("dtrtrs_");
 atomic_fetch_add(&cnt_dtrtrs_,1);original(a,b,c,d,e,f,g,h,i,j,s,t,u);
}
void dtrsv_(void*a,void*b,void*c,void*d,void*e,void*f,void*g,void*h,size_t s,size_t t,size_t u){
 typedef void(*fp)(void*,void*,void*,void*,void*,void*,void*,void*,size_t,size_t,size_t);
 static fp original;if(!original)original=(fp)next("dtrsv_");
 atomic_fetch_add(&cnt_dtrsv_,1);
 int32_t dim=lo32(d),lda=lo32(f),incx=lo32(h);
 struct rhs_event *event=NULL;
 if(dim==2 && lda>=2 && incx==1){
   event=event_new("dtrsv");
   if(event){
     event->side=a?*(char*)a:0;event->trans=b?*(char*)b:0;event->diag=c?*(char*)c:0;
     event->m=dim;event->n=1;event->k=0;
     save_numbers(event->before,g,2);
     save_numbers(event->a,e,4);
   }
 }
 original(a,b,c,d,e,f,g,h,s,t,u);
 if(event)save_numbers(event->after,g,2);
}
void dtrsm_(void*a,void*b,void*c,void*d,void*e,void*f,void*g,void*h,void*i,void*j,void*k,size_t s,size_t t,size_t u,size_t v){
 typedef void(*fp)(void*,void*,void*,void*,void*,void*,void*,void*,void*,void*,void*,size_t,size_t,size_t,size_t);
 static fp original;if(!original)original=(fp)next("dtrsm_");
 atomic_fetch_add(&cnt_dtrsm_,1);original(a,b,c,d,e,f,g,h,i,j,k,s,t,u,v);
}
/* Floating-return functions forward DOUBLE return, not void. */
double ddot_(void *a,void *b,void *c,void *d,void *e){
 typedef double (*fp)(void*,void*,void*,void*,void*);static fp original;
 if(!original)original=(fp)next("ddot_");
 atomic_fetch_add(&cnt_ddot_,1);
 return original(a,b,c,d,e);
}
double dnrm2_(void *a,void *b,void *c){
 typedef double (*fp)(void*,void*,void*);static fp original;
 if(!original)original=(fp)next("dnrm2_");
 atomic_fetch_add(&cnt_dnrm2_,1);
 return original(a,b,c);
}
__attribute__((destructor)) static void report(void) {
 const char *path=getenv("WLS_LAPACK_TRACE_LOG");if(!path||!*path)return;
 int fd=open(path,O_WRONLY|O_CREAT|O_APPEND,0600);if(fd<0)return;
 const char *names[]={"dgeqp3_","dgeqrf_","dgeqr2_","dorgqr_","dlarfg_",
  "dgelsy_","dgelsd_","dgesv_","dscal_","daxpy_","ddot_","dnrm2_",
  "dormqr_","dtrtrs_","dtrsv_","dtrsm_"};
 unsigned long counts[]={atomic_load(&cnt_dgeqp3_),atomic_load(&cnt_dgeqrf_),
 atomic_load(&cnt_dgeqr2_),atomic_load(&cnt_dorgqr_),atomic_load(&cnt_dlarfg_),
 atomic_load(&cnt_dgelsy_),atomic_load(&cnt_dgelsd_),atomic_load(&cnt_dgesv_),
 atomic_load(&cnt_dscal_),atomic_load(&cnt_daxpy_),atomic_load(&cnt_ddot_),
 atomic_load(&cnt_dnrm2_),atomic_load(&cnt_dormqr_),atomic_load(&cnt_dtrtrs_),
 atomic_load(&cnt_dtrsv_),atomic_load(&cnt_dtrsm_)};
 char buffer[256];
 for(size_t i=0;i<sizeof(counts)/sizeof(counts[0]);i++){
  int n=snprintf(buffer,sizeof(buffer),"WLS_LAPACK_CALL\tpid=%ld\tname=%s\tcount=%lu\n",
   (long)getpid(),names[i],counts[i]);
  if(n>0 && n<(int)sizeof(buffer)){ssize_t unused=write(fd,buffer,(size_t)n);(void)unused;}
 }
 close(fd);
 const char *rhs_path=getenv("WLS_NUMERIC_BUFFER_LOG");
 if(!rhs_path||!*rhs_path)return;
 FILE *out=fopen(rhs_path,"a");
 if(!out)return;
 unsigned total=atomic_load(&rhs_count);
 for(unsigned n=0;n<total&&n<MAX_STAGES;n++){
   const struct rhs_event *ev=&rhs_events[n];
   if(!ev->routine[0])continue;
   fprintf(out,"WLS_NUMERIC_BUFFER\tpid=%ld\tsequence=%u\troutine=%s\tflags=%c,%c,%c\tm=%d\tn=%d\tk=%d\tinfo=%d\tA=",
           (long)getpid(),n,ev->routine,ev->side,ev->trans,ev->diag,ev->m,ev->n,ev->k,ev->info);
   if(strcmp(ev->routine,"dtrsv")==0){
     for(unsigned j=0;j<4;j++)fprintf(out,"%s%016llx",j?",":"",(unsigned long long)ev->a[j]);
   }
   fprintf(out,"\tBEFORE=");
   for(int32_t j=0;j<ev->m;j++)fprintf(out,"%s%016llx",j?",":"",(unsigned long long)ev->before[j]);
   fprintf(out,"\tAFTER=");
   for(int32_t j=0;j<ev->m;j++)fprintf(out,"%s%016llx",j?",":"",(unsigned long long)ev->after[j]);
   fputc('\n',out);
 }
 fprintf(out,"WLS_NUMERIC_SUMMARY\tpid=%ld\tselected=%u\toverflow=%u\n",(long)getpid(),total,rhs_overflow);
 fclose(out);
}
