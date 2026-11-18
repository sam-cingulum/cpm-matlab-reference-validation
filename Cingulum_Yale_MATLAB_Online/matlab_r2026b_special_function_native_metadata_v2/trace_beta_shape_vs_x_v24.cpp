// Independently authored original MATLAB R2026b beta dynamic control flow probe.
// Only SHA-pinned licensed research host; only aggregate path metadata published.
// No original vendor numerical outputs, constants, operands or code exported.
#include <array>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <dlfcn.h>
#include <limits>

extern "C" {
volatile std::uintptr_t beta_probe_hidden_entry = 0;
volatile unsigned beta_probe_case_index = 0;
__attribute__((noinline,used)) void before_beta_original_call() {
    asm volatile("" ::: "memory");
}
}
struct BetaCase {
    double x,a,b;
    int tail;
};
int main(int argc,char**argv) {
    if(argc!=4) {
        std::fputs("Expected original R2026b library, symbol and hidden-entry offset\n",stderr);
        return 2;
    }
    void* lib=dlopen(argv[1],RTLD_NOW|RTLD_LOCAL);
    if(!lib) return 3;
    void* symbol=dlsym(lib,argv[2]);
    if(!symbol) return 4;
    Dl_info info{};
    if(!dladdr(symbol,&info)||!info.dli_fbase) return 5;
    beta_probe_hidden_entry=
        reinterpret_cast<std::uintptr_t>(info.dli_fbase)+std::strtoull(argv[3],nullptr,0);
    using Beta=double(*)(double,double,double,int);
    Beta beta=reinterpret_cast<Beta>(symbol);
    const std::array<BetaCase,24> rows{{
        {0.01,0.5,0.5,0},
        {0.01,0.5,0.5,1},
        {0.5,0.5,0.5,0},
        {0.5,0.5,0.5,1},
        {0.99,0.5,0.5,0},
        {0.99,0.5,0.5,1},
        {0.01,2.5,3.5,0},
        {0.01,2.5,3.5,1},
        {0.5,2.5,3.5,0},
        {0.5,2.5,3.5,1},
        {0.99,2.5,3.5,0},
        {0.99,2.5,3.5,1},
        {0.01,10.0,10.0,0},
        {0.01,10.0,10.0,1},
        {0.5,10.0,10.0,0},
        {0.5,10.0,10.0,1},
        {0.99,10.0,10.0,0},
        {0.99,10.0,10.0,1},
        {0.01,100.0,10.0,0},
        {0.01,100.0,10.0,1},
        {0.5,100.0,10.0,0},
        {0.5,100.0,10.0,1},
        {0.99,100.0,10.0,0},
        {0.99,100.0,10.0,1},
    }};
    volatile double check=0.0;
    for(unsigned i=0;i<rows.size();++i) {
        beta_probe_case_index=i;
        before_beta_original_call();
        const auto& v=rows[i];
        volatile double result=beta(v.x,v.a,v.b,v.tail);
        if(!std::isfinite(result))return 6;
        check=check+result/(i+1.0);
    }
    if(!std::isfinite(check))return 7;
    std::puts("ORIGINAL_V24_BETA_INNER_HELPER_SHAPE_VS_X_WITHOUT_ORIGINAL_OUTPUTS");
    dlclose(lib);
    return 0;
}
