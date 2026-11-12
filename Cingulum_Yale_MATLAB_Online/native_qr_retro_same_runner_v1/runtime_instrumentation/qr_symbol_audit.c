#define _GNU_SOURCE
#include <link.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <stdint.h>

/* Passive dynamic-loader instrumentation. No MathWorks binary modification.
 * Discover which exported BLAS/LAPACK functions are bound in a real MATLAB
 * qr call. Never intercept or change numeric operations at this stage. */
static int fd = -1;
static int enabled = 0;
static int interesting(const char *s) {
  const char *names[] = {"dlarfg", "dlarf", "dgeqr2", "dgeqrf", "dgeqp3", "dgeqpf", "dormqr", "dorgqr", "dgemv", "ddot", "daxpy", "dnrm2", "dscal", "dgemm", "DLARFG", "DLARF", "DGEQR2", "DGEQRF", "DGEQP3", "DORMQR", "DORGQR", "DGEMV", "DDOT", "DAXPY", "DNRM2", "DSCAL", "DGEMM"};
  for (size_t i=0;i<sizeof(names)/sizeof(names[0]);i++) if (strstr(s,names[i])) return 1;
  return 0;
}
unsigned int la_version(unsigned int v) {
  const char *path = getenv("QR_AUDIT_LOG");
  if (path && *path) { fd = open(path, O_WRONLY|O_CREAT|O_APPEND, 0600); enabled = fd>=0; }
  return v < LAV_CURRENT ? v : LAV_CURRENT;
}
unsigned int la_objopen(struct link_map *map, Lmid_t lmid, uintptr_t *cookie) {
  (void)lmid; *cookie = (uintptr_t)map;
  if (enabled && map && map->l_name) dprintf(fd,"OBJ\t%s\n",map->l_name);
  return LA_FLG_BINDTO | LA_FLG_BINDFROM;
}
uintptr_t la_symbind64(Elf64_Sym *sym, unsigned int ndx, uintptr_t *refcook,
                      uintptr_t *defcook, unsigned int *flags, const char *symname) {
  (void)ndx; (void)flags;
  if (enabled && interesting(symname)) {
    struct link_map *ref = (struct link_map *)*refcook;
    struct link_map *def = (struct link_map *)*defcook;
    dprintf(fd,"BIND\t%s\t%s\t%s\n",symname,
            ref && ref->l_name ? ref->l_name : "", def && def->l_name ? def->l_name : "");
  }
  return sym->st_value;
}
