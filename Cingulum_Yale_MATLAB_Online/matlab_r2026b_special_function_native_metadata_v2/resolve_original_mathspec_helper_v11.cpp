// Research-only runtime pointer resolver for SHA-pinned authorized R2026b.
// Prints only a library-relative destination and symbolic library identity,
// never vendor instruction bytes or numerical output. Not part of Rust product.
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <dlfcn.h>
#include <cmath>
#include <limits>

extern "C" {
volatile std::uintptr_t helper_probe_stub = 0;
volatile std::uintptr_t helper_probe_base = 0;
volatile std::uintptr_t helper_probe_after = 0;
}

extern "C" __attribute__((noinline,used)) void before_helper_probe() {
    asm volatile("" ::: "memory");
}
int main(int argc,char**argv) {
    if(argc!=4) return 2;
    void* lib=dlopen(argv[1], RTLD_NOW|RTLD_LOCAL);
    if(!lib) return 3;
    void* sym=dlsym(lib,argv[2]);
    if(!sym) return 4;
    Dl_info info{};
    if(!dladdr(sym,&info)||!info.dli_fbase) return 5;
    helper_probe_base=reinterpret_cast<std::uintptr_t>(info.dli_fbase);
    helper_probe_stub=helper_probe_base+std::strtoull(argv[3],nullptr,0);
    if(helper_probe_stub<=helper_probe_base) return 6;
    before_helper_probe(); // GDB stops here before any numerical call.
    using Gamma=double(*)(double);
    Gamma gamma=reinterpret_cast<Gamma>(sym);
    volatile double result=gamma(0.125);
    if(!std::isfinite(result)) return 7;
    helper_probe_after=helper_probe_stub;
    std::puts("ORIGINAL_R2026B_RESEARCH_HELPER_CALLED_NO_VENDOR_NUMERIC_OUTPUT");
    dlclose(lib);
    return 0;
}
