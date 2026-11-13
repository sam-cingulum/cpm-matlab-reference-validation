#define _GNU_SOURCE
#include <link.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
/* Passive ELF loader binding audit for ONLY previously disclosed synthetic
   weighted backslash. Symbol resolution is not proof of runtime call; use
   weighted_lapack_call_counter.c for instrumented call counts. */
static int fd=-1;
static int interesting(const char *name){
 const char *keys[]={"dgels","DGELS","dgeqr","DGEQR","dgeqp","DGEQP",
  "dormqr","DORMQR","dorgqr","DORGQR","dtrtrs","DTRTRS",
  "dtrsm","DTRSM","dgemv","DGEMV","ddot","DDOT",
  "dlarf","DLARF","dscal","DSCAL","daxpy","DAXPY",
  "dnrm2","DNRM2","dgetrf","DGETRF","dgesv","DGESV",
  "LAPACKE_dgels","LAPACKE_dgeqr"};
 for(size_t i=0;i<sizeof(keys)/sizeof(keys[0]);i++)
  if(strstr(name,keys[i]))return 1;
 return 0;
}
unsigned int la_version(unsigned int v){
 const char *path=getenv("WLS_BIND_AUDIT_LOG");
 if(path&&*path)fd=open(path,O_WRONLY|O_CREAT|O_APPEND,0600);
 return v<LAV_CURRENT?v:LAV_CURRENT;
}
unsigned int la_objopen(struct link_map *map,Lmid_t lmid,uintptr_t *cookie){
 (void)lmid;*cookie=(uintptr_t)map;
 if(fd>=0&&map&&map->l_name)dprintf(fd,"WLS_AUDIT_OBJECT\t%s\n",map->l_name);
 return LA_FLG_BINDTO|LA_FLG_BINDFROM;
}
uintptr_t la_symbind64(Elf64_Sym *sym,unsigned int ndx,uintptr_t *refcook,
 uintptr_t *defcook,unsigned int *flags,const char *name){
 (void)ndx;(void)flags;
 if(fd>=0 && interesting(name)){
  struct link_map *r=(struct link_map *)*refcook;
  struct link_map *d=(struct link_map *)*defcook;
  dprintf(fd,"WLS_AUDIT_SYMBOL\t%s\t%s\t%s\n",name,
    r&&r->l_name?r->l_name:"",d&&d->l_name?d->l_name:"");
 }
 return sym->st_value;
}
