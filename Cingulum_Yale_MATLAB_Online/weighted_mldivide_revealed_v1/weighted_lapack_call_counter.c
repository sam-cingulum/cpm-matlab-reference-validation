#define _GNU_SOURCE
#include <dlfcn.h>
#include <fcntl.h>
#include <stdatomic.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
/* Passive source-revealed six-case MathWorks weighted backslash study.
 * All function pointers forwarded verbatim, and no float calculations or
 * file I/O on hot paths. Only no-character Fortran-ABI routines wrapped.
 * Always compare an uninstrumented MATLAB result bytewise, and FAIL if
 * any numerical difference is introduced by LD_PRELOAD instrumentation.
 */
static void *next(const char *name) {
 void *p=dlsym(RTLD_NEXT,name);
 if(!p) {write(2,"WLS_TRACE_SYMBOL_NOT_FOUND\n",27);_exit(127);}
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
  "dgelsy_","dgelsd_","dgesv_","dscal_","daxpy_","ddot_","dnrm2_"};
 unsigned long counts[]={atomic_load(&cnt_dgeqp3_),atomic_load(&cnt_dgeqrf_),
 atomic_load(&cnt_dgeqr2_),atomic_load(&cnt_dorgqr_),atomic_load(&cnt_dlarfg_),
 atomic_load(&cnt_dgelsy_),atomic_load(&cnt_dgelsd_),atomic_load(&cnt_dgesv_),
 atomic_load(&cnt_dscal_),atomic_load(&cnt_daxpy_),atomic_load(&cnt_ddot_),
 atomic_load(&cnt_dnrm2_)};
 char buffer[256];
 for(size_t i=0;i<sizeof(counts)/sizeof(counts[0]);i++){
  int n=snprintf(buffer,sizeof(buffer),"WLS_LAPACK_CALL\tpid=%ld\tname=%s\tcount=%lu\n",
   (long)getpid(),names[i],counts[i]);
  if(n>0 && n<(int)sizeof(buffer)){ssize_t unused=write(fd,buffer,(size_t)n);(void)unused;}
 }
 close(fd);
}
