// Original R2026b research ABI caller for debugger-only *branch metadata*.
// No proprietary code, intermediate values or MATLAB numeric outputs exported.
// Run only with authorized SHA-verified installed MathWorks R2026b.
#include <array>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <dlfcn.h>
#include <limits>

extern "C" {
volatile std::uintptr_t gamma_probe_hidden_entry = 0;
volatile unsigned gamma_probe_case_index = 0;
__attribute__((noinline,used)) void before_gamma_original_call() {
    asm volatile("" ::: "memory");
}
}
int main(int argc, char** argv) {
    if (argc != 4) {
        std::fprintf(stderr,"usage: original_gamma_trace LIBRARY MANGLED_GAMMALN_SYMBOL HIDDEN_ENTRY_OFFSET\n");
        return 2;
    }
    void* lib = dlopen(argv[1], RTLD_NOW | RTLD_LOCAL);
    if (!lib) { std::fprintf(stderr,"dlopen failed\n"); return 3; }
    void* symbol = dlsym(lib, argv[2]);
    if (!symbol) { std::fprintf(stderr,"dlsym failed\n"); return 4; }
    Dl_info info{};
    if (!dladdr(symbol, &info) || !info.dli_fbase) return 5;
    const auto offset = std::strtoull(argv[3], nullptr, 0);
    if (offset == 0) return 6;
    gamma_probe_hidden_entry = reinterpret_cast<std::uintptr_t>(info.dli_fbase) + offset;
    using GammaFn = double(*)(double);
    const auto gamma = reinterpret_cast<GammaFn>(symbol);
    // Source-independent mathematically preregistered Cody-style boundaries to isolate recurrence and
    // rational/polynomial branch families. No original oracle values supplied.
    constexpr std::array<double,24> xs = {
        std::nextafter(0.5,0.0), 0.5, std::nextafter(0.5,1.0),
        std::nextafter(1.5,1.0), 1.5, std::nextafter(1.5,2.0),
        std::nextafter(4.0,3.0), 4.0, std::nextafter(4.0,5.0),
        std::nextafter(12.0,11.0), 12.0, std::nextafter(12.0,13.0),
        std::nextafter(2.0,1.0), 2.0, std::nextafter(2.0,3.0),
        std::nextafter(8.0,7.0), 8.0, std::nextafter(8.0,9.0),
        0.75, 1.25, 2.5, 5.5, 10.25, 1000.25
    };
    volatile double checksum = 0.0;
    for (unsigned i = 0; i < xs.size(); ++i) {
        gamma_probe_case_index = i;
        before_gamma_original_call();
        volatile double original_value = gamma(xs[i]);
        if (!std::isfinite(original_value)) return 7;
        checksum = checksum + original_value * (1.0 / (i + 1.0));
    }
    if (!std::isfinite(checksum)) return 8;
    std::puts("ORIGINAL_ABI_BOUNDARY_RESEARCH_CALLS_EXECUTED_24_NO_ORIGINAL_NUMERIC_OUTPUT");
    dlclose(lib);
    return 0;
}
