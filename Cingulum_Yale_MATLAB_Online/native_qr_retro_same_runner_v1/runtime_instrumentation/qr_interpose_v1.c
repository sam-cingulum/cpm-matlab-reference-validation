#define _GNU_SOURCE
#include <dlfcn.h>
#include <fcntl.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdatomic.h>
#include <unistd.h>

/* True function-entry counter through ELF symbol interposition. The counters
   are incremented atomically; no file I/O or floating-point work in the QR
   call path. The call is forwarded unchanged to the original symbol. The
   result MUST be compared bit-for-bit with the uninstrumented MATLAB oracle.
   Fortran LAPACK entrypoints take only pointers, so their calling conventions
   are independent of LP64/ILP64 integer widths. */
static _Atomic unsigned long n_dgeqp3;
static _Atomic unsigned long n_dgeqr2;
static _Atomic unsigned long n_dgeqrf;
static _Atomic unsigned long n_dlarfg;
static _Atomic unsigned long n_dlarf;
static _Atomic unsigned long n_lapacke_dgeqp3;
static _Atomic unsigned long n_lapacke_dgeqr2;
static _Atomic unsigned long n_lapacke_dgeqrf;

static void *resolve(const char *name) {
  void *p = dlsym(RTLD_NEXT, name);
  if (!p) {
    const char *message = "QR_INTERPOSE_ERROR unresolved original symbol\n";
    ssize_t ignored = write(2, message, sizeof("QR_INTERPOSE_ERROR unresolved original symbol\n")-1);
    (void)ignored;
    _exit(127);
  }
  return p;
}

#define FORTRAN_WRAPPER_5(name, counter) \
void name(void *a,void *b,void *c,void *d,void *e){ \
  typedef void (*fptr)(void*,void*,void*,void*,void*); \
  static fptr fn; if(!fn)fn=(fptr)resolve(#name); \
  atomic_fetch_add_explicit(&counter,1,memory_order_relaxed);fn(a,b,c,d,e); }
#define FORTRAN_WRAPPER_9(name, counter) \
void name(void *a,void *b,void *c,void *d,void *e,void *f,void *g,void *h,void *i){ \
  typedef void (*fptr)(void*,void*,void*,void*,void*,void*,void*,void*,void*); \
  static fptr fn; if(!fn)fn=(fptr)resolve(#name); \
  atomic_fetch_add_explicit(&counter,1,memory_order_relaxed);fn(a,b,c,d,e,f,g,h,i); }
#define FORTRAN_WRAPPER_8(name, counter) \
void name(void *a,void *b,void *c,void *d,void *e,void *f,void *g,void *h){ \
  typedef void (*fptr)(void*,void*,void*,void*,void*,void*,void*,void*); \
  static fptr fn; if(!fn)fn=(fptr)resolve(#name); \
  atomic_fetch_add_explicit(&counter,1,memory_order_relaxed);fn(a,b,c,d,e,f,g,h); }
#define FORTRAN_WRAPPER_7(name, counter) \
void name(void *a,void *b,void *c,void *d,void *e,void *f,void *g){ \
  typedef void (*fptr)(void*,void*,void*,void*,void*,void*,void*); \
  static fptr fn; if(!fn)fn=(fptr)resolve(#name); \
  atomic_fetch_add_explicit(&counter,1,memory_order_relaxed);fn(a,b,c,d,e,f,g); }
#ifndef QR_INTERPOSE_OVERRIDE_DGEQP3
FORTRAN_WRAPPER_9(dgeqp3_, n_dgeqp3)
#endif
FORTRAN_WRAPPER_7(dgeqr2_, n_dgeqr2)
FORTRAN_WRAPPER_8(dgeqrf_, n_dgeqrf)
FORTRAN_WRAPPER_5(dlarfg_, n_dlarfg)
FORTRAN_WRAPPER_9(dlarf_, n_dlarf)

/* LAPACKE uses integer scalars plus pointers. Use intptr_t-width scalars for
   LP64/ILP64-compatible register forwarding on x86-64, and never inspect
   or modify their contents. Test output parity before accepting any results. */
typedef long (*lapacke_qp3_fn)(long,long,long,void*,long,void*,void*);
long LAPACKE_dgeqp3(long layout,long m,long n,void *a,long lda,void *jpvt,void *tau){
 static lapacke_qp3_fn fn; if(!fn)fn=(lapacke_qp3_fn)resolve("LAPACKE_dgeqp3");
 atomic_fetch_add_explicit(&n_lapacke_dgeqp3,1,memory_order_relaxed);
 return fn(layout,m,n,a,lda,jpvt,tau);
}
typedef long (*lapacke_qr_fn)(long,long,long,void*,long,void*);
long LAPACKE_dgeqr2(long layout,long m,long n,void *a,long lda,void *tau){
 static lapacke_qr_fn fn; if(!fn)fn=(lapacke_qr_fn)resolve("LAPACKE_dgeqr2");
 atomic_fetch_add_explicit(&n_lapacke_dgeqr2,1,memory_order_relaxed);
 return fn(layout,m,n,a,lda,tau);
}
long LAPACKE_dgeqrf(long layout,long m,long n,void *a,long lda,void *tau){
 static lapacke_qr_fn fn; if(!fn)fn=(lapacke_qr_fn)resolve("LAPACKE_dgeqrf");
 atomic_fetch_add_explicit(&n_lapacke_dgeqrf,1,memory_order_relaxed);
 return fn(layout,m,n,a,lda,tau);
}

__attribute__((destructor)) static void report(void){
 const char *path=getenv("QR_INTERPOSE_LOG");if(!path||!*path)return;
 char exe[1024]={0};ssize_t n=readlink("/proc/self/exe",exe,sizeof(exe)-1);
 if(n<0)exe[0]=0;else exe[n]=0;
 int fd=open(path,O_WRONLY|O_CREAT|O_APPEND,0600);if(fd<0)return;
 unsigned long counts[]={
  atomic_load(&n_dgeqp3),atomic_load(&n_dgeqr2),atomic_load(&n_dgeqrf),
  atomic_load(&n_dlarfg),atomic_load(&n_dlarf),
  atomic_load(&n_lapacke_dgeqp3),atomic_load(&n_lapacke_dgeqr2),atomic_load(&n_lapacke_dgeqrf)};
 const char *names[]={"dgeqp3_","dgeqr2_","dgeqrf_","dlarfg_","dlarf_", "LAPACKE_dgeqp3","LAPACKE_dgeqr2","LAPACKE_dgeqrf"};
 char buf[1400];for(int i=0;i<8;i++){
  int written=snprintf(buf,sizeof(buf),"QR_INTERPOSE_COUNT\tpid=%ld\texe=%s\tname=%s\tcount=%lu\n",(long)getpid(),exe,names[i],counts[i]);
  if(written>0 && written<(int)sizeof(buf)){ssize_t ignored=write(fd,buf,(size_t)written);(void)ignored;}
 }
 close(fd);
}
