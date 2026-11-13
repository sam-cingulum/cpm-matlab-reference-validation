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
DECLARE_COUNTER(dgemv_)
/* In-memory snapshots from only small disclosed synthetic weighted solvers.
 * No filesystem activity within the original vendor numerics. Capturing
 * bytes does not alter FPU state, input arrays, or their arithmetic. */
#define MAX_STAGES 4096
#define MAX_SAMPLES 25
struct rhs_event {
 char routine[8], side, trans, diag;
 int32_t m,n,k,info;
 uint64_t before[MAX_SAMPLES],after[MAX_SAMPLES],first_stage[MAX_SAMPLES],a[4];
 uint64_t packed_a[2*MAX_SAMPLES],tau_vals[2];
 int32_t first_stage_valid;
};
static struct rhs_event rhs_events[MAX_STAGES];
static _Atomic unsigned rhs_count;
static unsigned rhs_overflow;
/* 16,365 controlled cancellation triples for six previously disclosed V9
 * AMD DORMQR dimensions. Every probe is synthetic and uses the genuine
 * original exported vendor LAPACK at runtime. No vendor code is copied. */
#define MAX_MICROS 20000
struct cancellation_event {
 uint8_t m,i,j,k,permutation,observer,invalid;
 uint64_t output_bits;
};
static struct cancellation_event micro_events[MAX_MICROS];
static _Atomic unsigned micro_count;
static _Atomic unsigned micro_mask;
static _Atomic unsigned micro_failures;
typedef void(*dormqr_original_fn)(
 void*,void*,void*,void*,void*,void*,void*,void*,void*,void*,void*,void*,void*,size_t,size_t);
static void run_disclosed_dormqr_cancellation_triples(int rows,dormqr_original_fn original){
 if(!getenv("WLS_DORMQR_CANCELLATION_TRIPLES"))return;
 if(rows<9||rows>MAX_SAMPLES)return;
 unsigned mask=(unsigned)1u<<(unsigned)rows;
 if(atomic_fetch_or(&micro_mask,mask)&mask)return;
 /* C is width-one. Fabricated reflector v_i=1, tau=1 and C_observer=0.
  * Original MATLAB DORMQR's output C_observer is exactly minus its dot.
  * Include leaf 0 in the tree. Use +/-2^54, NOT +/-2^53: +1 is then
  * swallowed by BOTH signs (no asymmetric boundary near -2^53), so a
  * binary reduction tree yields exactly ONE nonzero of the three probes
  * for each three-leaf triple. */
 double packed_a[MAX_SAMPLES];
 for(int z=0;z<rows;z++)packed_a[z]=1.0;
 double tau=1.0;
 int64_t m=(int64_t)rows,n=1,k=1,lda=m,ldc=m,lwork=512;
 char side='L',trans='T';
 for(int i=0;i<rows-2;i++)for(int j=i+1;j<rows-1;j++)for(int kidx=j+1;kidx<rows;kidx++){
  for(int perm=0;perm<3;perm++){
   unsigned slot=atomic_fetch_add(&micro_count,1);
   if(slot>=MAX_MICROS){atomic_fetch_add(&micro_failures,1);return;}
   int big=(perm==2)?j:i;
   int neg=(perm==0)?j:kidx;
   int unit=(perm==0)?kidx:((perm==1)?j:i);
   int observer=0;
   while(observer==i||observer==j||observer==kidx)observer++;
   uint64_t saved=0;
   int bad=0;
   for(int repeat=0;repeat<2;repeat++){
    double rhs[MAX_SAMPLES]={0.0};
    double work[512]={0.0};
    rhs[big]=0x1p54;rhs[neg]=-0x1p54;rhs[unit]=1.0;
    int64_t info=0;
    original(&side,&trans,&m,&n,&k,packed_a,&lda,&tau,rhs,&ldc,work,&lwork,&info,1,1);
    uint64_t observed=0;
    memcpy(&observed,&rhs[observer],8);
    if(info!=0||!__builtin_isfinite(rhs[observer]))bad=1;
    if(repeat==0)saved=observed;
    else if(observed!=saved)bad=1;
   }
   struct cancellation_event *e=&micro_events[slot];
   e->m=(uint8_t)rows;e->i=(uint8_t)i;e->j=(uint8_t)j;
   e->k=(uint8_t)kidx;e->permutation=(uint8_t)perm;e->observer=(uint8_t)observer;
   e->invalid=(uint8_t)bad;e->output_bits=saved;
   if(bad)atomic_fetch_add(&micro_failures,1);
  }
 }
}
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
 static dormqr_original_fn original;if(!original)original=(dormqr_original_fn)next("dormqr_");
 atomic_fetch_add(&cnt_dormqr_,1);
 int32_t rows=lo32(c),columns=lo32(d),reflectors=lo32(e),lda=lo32(g),ldc=lo32(j),work=lo32(l);
 struct rhs_event *event=NULL;
 if(rows>=9&&rows<=MAX_SAMPLES&&columns==1&&reflectors==2&&lda>=rows&&ldc>=rows&&work>=1){
   event=event_new("dormqr");
   if(event){
     event->side=a?*(char*)a:0;event->trans=b?*(char*)b:0;event->diag='-';
     event->m=rows;event->n=columns;event->k=reflectors;
     save_numbers(event->before,i,(unsigned)rows);
     const unsigned char *ap=(const unsigned char*)f;
     for(int column=0;column<2;column++){
       for(int row=0;row<rows;row++){
         memcpy(&event->packed_a[column*rows+row],ap+8u*((size_t)column*(size_t)lda+(size_t)row),8);
       }
     }
     save_numbers(event->tau_vals,h,2);
   }
 }
 original(a,b,c,d,e,f,g,h,i,j,k,l,m,s,t);
 if(event){
   save_numbers(event->after,i,(unsigned)rows);
   event->info=lo32(m);
   /* Instrumentation-only controlled synthetic shadow: genuine original
    * DORMQR with k=1 on an independently allocated copy of original C,
    * AFTER the genuine k=2 production call has returned. Source C is not
    * changed and the original output must match a completely clean run
    * byte-for-byte. This exposes the first reflector result without any
    * proprietary MATLAB source or vendor binary redistribution. */
   if(getenv("WLS_CAPTURE_DORMQR_STAGE1")){
     double tmp_c[MAX_SAMPLES]={0},tmp_work[512]={0};
     memcpy(tmp_c,event->before,(size_t)rows*sizeof(double));
     int64_t one=1,ldtmp=rows,lwtmp=512,infotmp=0;
     original(a,b,c,d,&one,f,g,h,tmp_c,&ldtmp,tmp_work,&lwtmp,&infotmp,s,t);
     if(infotmp==0){
       save_numbers(event->first_stage,tmp_c,(unsigned)rows);
       event->first_stage_valid=1;
     }
   }
   run_disclosed_dormqr_cancellation_triples(rows,original);
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
     /* DTRSV uses the UPPER TRIANGLE at column-major LDA. The intervening
      * packed Householder entries are NOT R[1,0] or R[0,1]. Earlier v3
      * contiguous-A capture could falsely suggest a different R. */
     save_numbers(event->a,e,1);
     event->a[1]=0;
     const unsigned char *base=(const unsigned char*)e;
     memcpy(&event->a[2],base+8u*(size_t)lda,8);
     memcpy(&event->a[3],base+8u*((size_t)lda+1u),8);
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
void dgemv_(void*a,void*b,void*c,void*d,void*e,void*f,void*g,void*h,void*i,void*j,void*k,size_t len){
 typedef void(*fp)(void*,void*,void*,void*,void*,void*,void*,void*,void*,void*,void*,size_t);
 static fp original;if(!original)original=(fp)next("dgemv_");
 atomic_fetch_add(&cnt_dgemv_,1);original(a,b,c,d,e,f,g,h,i,j,k,len);
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
  "dormqr_","dtrtrs_","dtrsv_","dtrsm_","dgemv_"};
 unsigned long counts[]={atomic_load(&cnt_dgeqp3_),atomic_load(&cnt_dgeqrf_),
 atomic_load(&cnt_dgeqr2_),atomic_load(&cnt_dorgqr_),atomic_load(&cnt_dlarfg_),
 atomic_load(&cnt_dgelsy_),atomic_load(&cnt_dgelsd_),atomic_load(&cnt_dgesv_),
 atomic_load(&cnt_dscal_),atomic_load(&cnt_daxpy_),atomic_load(&cnt_ddot_),
 atomic_load(&cnt_dnrm2_),atomic_load(&cnt_dormqr_),atomic_load(&cnt_dtrtrs_),
 atomic_load(&cnt_dtrsv_),atomic_load(&cnt_dtrsm_),atomic_load(&cnt_dgemv_)};
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
   if(ev->first_stage_valid){
      fprintf(out,"\tFIRST_STAGE=");
      for(int32_t j=0;j<ev->m;j++)fprintf(out,"%s%016llx",j?",":"",(unsigned long long)ev->first_stage[j]);
   }
   if(strcmp(ev->routine,"dormqr")==0){
     fprintf(out,"\tPACKED_A=");
     for(int32_t j=0;j<ev->m*2;j++)fprintf(out,"%s%016llx",j?",":"",(unsigned long long)ev->packed_a[j]);
     fprintf(out,"\tTAU=%016llx,%016llx",(unsigned long long)ev->tau_vals[0],(unsigned long long)ev->tau_vals[1]);
   }
   fputc('\n',out);
 }
 fprintf(out,"WLS_NUMERIC_SUMMARY\tpid=%ld\tselected=%u\toverflow=%u\n",(long)getpid(),total,rhs_overflow);
 fclose(out);
 const char *micro_path=getenv("WLS_DORMQR_CANCELLATION_TRIPLES");
 if(micro_path&&*micro_path){
  FILE *mfile=fopen(micro_path,"a");
  if(mfile){
   unsigned count=atomic_load(&micro_count);
   for(unsigned idx=0;idx<count&&idx<MAX_MICROS;idx++){
     const struct cancellation_event *e=&micro_events[idx];
     fprintf(mfile,"VENDOR_DORMQR_TRIPLE\twidth=%u\ti=%u\tj=%u\tk=%u\tunit_position=%u\tobserver=%u\toutput=%016llx\tinvalid=%u\n",
       e->m,e->i,e->j,e->k,e->permutation,e->observer,
       (unsigned long long)e->output_bits,e->invalid);
   }
   fprintf(mfile,"VENDOR_DORMQR_TRIPLE_SUMMARY\tpid=%ld\ttriples=%u\tfailures=%u\n",
     (long)getpid(),count,atomic_load(&micro_failures));
   fclose(mfile);
  }
 }
}
