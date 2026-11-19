// Public numerical ABI caller. Inputs come exclusively from the synthetic TSV.
#include <cmath>
#include <cstdint>
#include <cstring>
#include <dlfcn.h>
#include <fstream>
#include <sstream>
#include <string>

extern "C" {
volatile std::uintptr_t probe_base;
volatile unsigned probe_index;
__attribute__((noinline)) void before_call(double control) {
    asm volatile("" : : "x"(control) : "memory");
}
}

double unpack(const std::string& hex) {
    auto bits = std::stoull(hex, nullptr, 16);
    double d;
    std::memcpy(&d, &bits, sizeof(d));
    return d;
}

int main(int argc, char** argv) {
    if (argc != 4) return 1;
    void* library = dlopen(argv[1], RTLD_NOW | RTLD_LOCAL);
    if (!library) return 2;
    auto symbol = dlsym(library, argv[2]);
    Dl_info info{};
    if (!symbol || !dladdr(symbol, &info)) return 3;
    probe_base = reinterpret_cast<std::uintptr_t>(info.dli_fbase);
    auto beta = reinterpret_cast<double(*)(double,double,double,int)>(symbol);
    std::ifstream input(argv[3]);
    std::string line;
    std::getline(input, line);
    unsigned idx = 0;
    while (std::getline(input, line)) {
        std::istringstream fields(line);
        std::string id, ah, bh, xh;
        int upper;
        if (!(fields >> id >> ah >> bh >> xh >> upper)) return 4;
        double a = unpack(ah), b = unpack(bh), x = unpack(xh);
        probe_index = idx++;
        before_call(x);
        if (!std::isfinite(beta(x, a, b, upper))) return 5;
    }
    return idx == 60 ? 0 : 6;
}
