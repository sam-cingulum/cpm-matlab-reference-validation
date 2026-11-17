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
    const double low=std::nextafter(0.5,0.0);
    const double hi=std::nextafter(0.5,1.0);
    const std::array<BetaCase,28> rows{{
        {0.2,0.5,0.5,0}, {0.2,0.5,0.5,1},
        {0.8,0.5,0.5,0}, {0.8,0.5,0.5,1},
        {0.25,1.0,2.0,0}, {0.25,1.0,2.0,1},
        {0.75,2.0,1.0,0}, {0.75,2.0,1.0,1},
        {low,10.0,10.0,0}, {low,10.0,10.0,1},
        {hi,10.0,10.0,0}, {hi,10.0,10.0,1},
        {0.3,0.75,1.25,0}, {0.3,0.75,1.25,1},
        {0.4,2.5,3.5,0}, {0.4,2.5,3.5,1},
        {0.3,20.5,11.5,0}, {0.3,20.5,11.5,1},
        {0.8,100.0,10.0,0}, {0.8,100.0,10.0,1},
        {0.1,10.0,100.0,0}, {0.1,10.0,100.0,1},
        {0.05,0.75,13.25,0}, {0.05,0.75,13.25,1},
        {1.0/1024.0,0.01,240.0,0}, {1.0/1024.0,0.01,240.0,1},
        {1023.0/1024.0,240.0,0.01,0}, {1023.0/1024.0,240.0,0.01,1}
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
    std::puts("ORIGINAL_BETA_BRANCH_CALLS_EXECUTED_WITHOUT_ORIGINAL_OUTPUTS");
    dlclose(lib);
    return 0;
}
