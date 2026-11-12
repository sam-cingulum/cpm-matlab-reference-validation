#define _GNU_SOURCE
#include <dlfcn.h>
#include <fcntl.h>
#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

/* ELF dispatch inspection only: original QR delegate called unmodified.
   No numerical buffer reads and no side effects in the computational path.
   Inspect vector-table pointers at process teardown, then verify against an
   uninstrumented MATLAB binary64 control before accepting evidence. */
static unsigned long qr_count;
void dgeqp3_(void *m,void *n,void *a,void *lda,void *jpvt,void *tau,void *work,void *lwork,void *info){
 typedef void (*original_fn)(void*,void*,void*,void*,void*,void*,void*,void*,void*);
 static original_fn original;
 if (!original) {
  void *address=dlsym(RTLD_NEXT,"dgeqp3_");
  if(!address){_exit(127);}
  original=(original_fn)address;
 }
 qr_count++;
 original(m,n,a,lda,jpvt,tau,work,lwork,info);
}
static void inspect(FILE *f,const char *name){
 void *sym=dlsym(RTLD_DEFAULT,name);
 if (!sym) {fprintf(f,"QR_DISPATCH\tname=%s\tpresent=0\n",name);return;}
 void *target=NULL;memcpy(&target,sym,sizeof(target));
 Dl_info owner={0},destination={0};
 int ok1=dladdr(sym,&owner);
 int ok2=target ? dladdr(target,&destination):0;
 uint64_t offset=(ok2&&destination.dli_fbase) ? (uint64_t)((uintptr_t)target-(uintptr_t)destination.dli_fbase):0;
 fprintf(f,"QR_DISPATCH\tname=%s\tpresent=1\ttarget_mapped=%d\towner=%s\ttarget_object=%s\tobject_offset=0x%" PRIx64 "\ttarget_symbol=%s\n",
  name,ok2,ok1&&owner.dli_fname?owner.dli_fname:"UNKNOWN",
  ok2&&destination.dli_fname?destination.dli_fname:"UNKNOWN",offset,
  ok2&&destination.dli_sname?destination.dli_sname:"UNKNOWN");
}
__attribute__((destructor))static void record_dispatch(void){
 const char *path=getenv("QR_DISPATCH_PROBE_LOG");if(!path||!*path||!qr_count)return;
 int fd=open(path,O_WRONLY|O_CREAT|O_APPEND,0600);if(fd<0)return;
 FILE *out=fdopen(fd,"a");if(!out){close(fd);return;}
 char executable[1024]={0};ssize_t n=readlink("/proc/self/exe",executable,sizeof(executable)-1);
 if(n>0)executable[n]=0;
 fprintf(out,"QR_DISPATCH_PROCESS\tpid=%ld\texecutable=%s\tdgeqp3_calls=%lu\n",(long)getpid(),executable,qr_count);
 const char *symbols[]={"dgeqp3_vector","dgeqpf_vector","dlarfg_vector","dlarf_vector","dlarf1f_vector","dgeqr2_vector","dgeqrf_vector","dgemv_vector","dger_vector","ddot_vector","daxpy_vector","dnrm2_vector","dscal_vector","drot_vector"};
 for(unsigned i=0;i<sizeof(symbols)/sizeof(symbols[0]);i++) inspect(out,symbols[i]);
 fclose(out);
}
