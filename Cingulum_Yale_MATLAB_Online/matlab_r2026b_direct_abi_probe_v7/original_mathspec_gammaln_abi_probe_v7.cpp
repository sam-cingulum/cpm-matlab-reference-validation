// Scientific MATLAB R2026b ABI call-boundary test only.
// This user-authored test is executed ONLY on an authenticated, genuine MATLAB
// installation's hosted runner. It is not Cingulum pure Rust, not production,
// not a MATLAB licence bypass, and not a replacement for original MATLAB.
// No MathWorks compiled vendor binary or generated implementation is copied.
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <dlfcn.h>
#include <string>
#include <cstdlib>
int main(int argc,char**argv) {
    if (argc!=4) {
        std::fprintf(stderr,"usage: original_abi_probe LIB_PATH SYMBOL_MANGLED INPUT_HEX64\n");
        return 2;
    }
    void* lib=dlopen(argv[1],RTLD_NOW|RTLD_LOCAL);
    if (!lib) {
        std::fprintf(stderr,"ABI_DLOPEN_UNAVAILABLE: %s\n",dlerror());
        return 3;
    }
    void* sym=dlsym(lib,argv[2]);
    if (!sym) {
        std::fprintf(stderr,"ABI_SYMBOL_NOT_FOUND: %s\n",dlerror());
        return 4;
    }
    const std::string hex=argv[3];
    if (hex.size()!=16) return 5;
    std::uint64_t bits=std::strtoull(hex.c_str(),nullptr,16);
    double in;
    static_assert(sizeof(bits)==sizeof(in),"f64 required");
    std::memcpy(&in,&bits,sizeof(in));
    if (!(std::isfinite(in)&&in>0.0)) return 6;
    using Fn = double(*)(double);
    Fn func=reinterpret_cast<Fn>(sym);
    volatile double out=func(in);
    std::uint64_t out_bits;
    std::memcpy(&out_bits,(const void*)&out,sizeof(out));
    std::printf("ABI_NUMERIC_HEX input=%016llx output=%016llx\n",
                (unsigned long long)bits,(unsigned long long)out_bits);
    dlclose(lib);
    return 0;
}
