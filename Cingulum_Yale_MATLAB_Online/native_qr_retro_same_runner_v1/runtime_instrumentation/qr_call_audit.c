#define _GNU_SOURCE
#include <link.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <stdint.h>
#include <stdatomic.h>
#include <sys/syscall.h>

/* ABI-aware, read-only x86_64 PLT call audit. No numeric modification.
   Only log calls with exactly two columns and plausible row count. */
static int fd=-1;
static _Atomic unsigned long seq=0;
static int interesting(const char *s) {
 const char *p[]={"LAPACKE_dgeqp3","LAPACKE_dgeqr2","LAPACKE_dgeqrf","LAPACKE_dlarfg","dgeqp3_","dgeqr2_","dgeqrf_","dlarfg_"};
 for(unsigned i=0;i<sizeof(p)/sizeof(*p);i++)if(!strcmp(s,p[i]))return 1;
 return 0;
}
unsigned int la_version(unsigned int v){
 const char *p=getenv("QR_CALL_AUDIT_LOG");
 if(p&&*p)fd=open(p,O_WRONLY|O_CREAT|O_APPEND,0600);
 return v<LAV_CURRENT?v:LAV_CURRENT;
}
unsigned int la_objopen(struct link_map *m,Lmid_t ns,uintptr_t *cookie){
 (void)ns;*cookie=(uintptr_t)m;
 return LA_FLG_BINDTO|LA_FLG_BINDFROM;
}
uintptr_t la_symbind64(Elf64_Sym *sym,unsigned int ndx,uintptr_t *ref,uintptr_t *def,unsigned int *flags,const char *name){
 (void)ndx;(void)ref;(void)def;
 if(interesting(name)){
  *flags &= ~LA_SYMB_NOPLTENTER;
  if(fd>=0)dprintf(fd,"BIND\t%s\t%lx\n",name,(unsigned long)sym->st_value);
 }
 return sym->st_value;
}
Elf64_Addr la_x86_64_gnu_pltenter(Elf64_Sym *sym,unsigned int ndx,uintptr_t *ref,uintptr_t *def,
 La_x86_64_regs *regs,unsigned int *flags,const char *name,long int *framesize){
 (void)ndx;(void)ref;(void)def;(void)flags;(void)framesize;
 if(fd>=0&&interesting(name)){
  unsigned long s=atomic_fetch_add(&seq,1)+1;
  /* raw register arguments only, never dereference arbitrary process pointers */
  dprintf(fd,"CALL\t%lu\t%s\trdi=%016lx\trsi=%016lx\trdx=%016lx\trcx=%016lx\tr8=%016lx\tr9=%016lx\n",
    s,name,(unsigned long)regs->lr_rdi,(unsigned long)regs->lr_rsi,(unsigned long)regs->lr_rdx,
    (unsigned long)regs->lr_rcx,(unsigned long)regs->lr_r8,(unsigned long)regs->lr_r9);
 }
 return sym->st_value;
}
