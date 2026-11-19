// Original-only numerical observation. Breakpoints are confined to public
// system libm entry points and the two markers in this test executable.
#include <array>
#include <bit>
#include <cstdint>
#include <dlfcn.h>
#include <iomanip>
#include <iostream>
#include <string>

const char *names[] = {"log", "log1p", "log2", "log10", "exp", "expm1", "exp2",
                       "pow", "lgamma", "lgamma_r", "tgamma", "frexp", "ldexp", "scalbn"};
constexpr size_t count = sizeof(names) / sizeof(*names);
void *system_math[count][2]{};
extern "C" __attribute__((noinline)) void before_probe() { asm volatile("" ::: "memory"); }
extern "C" __attribute__((noinline)) void after_probe() { asm volatile("" ::: "memory"); }

int main(int argc, char **argv) {
    if (argc != 3) return 2;
    auto *lib = dlopen(argv[1], RTLD_NOW | RTLD_LOCAL);
    auto *sys = dlopen("libm.so.6", RTLD_NOW | RTLD_LOCAL);
    if (!lib || !sys) return 3;
    using Gamma = double (*)(double, double, int);
    using Unary = double (*)(double);
    auto gamma = reinterpret_cast<Gamma>(dlsym(lib, argv[2]));
    if (!gamma) return 4;
    for (size_t i = 0; i < count; ++i) {
        system_math[i][0] = dlsym(sys, names[i]);
        system_math[i][1] = dlvsym(sys, names[i], "GLIBC_2.2.5");
        if (!system_math[i][0]) return 5;
    }
    auto logx = reinterpret_cast<Unary>(system_math[0][0]);
    auto expx = reinterpret_cast<Unary>(system_math[4][0]);
    std::string id, shape;
    while (std::cin >> id >> shape) {
        auto a = std::bit_cast<double>(std::stoull(shape, nullptr, 16));
        auto x = std::bit_cast<double>(std::stoull(id, nullptr, 16));
        for (int mode = 0; mode < 3; ++mode) {
            before_probe();
            double y = mode == 2 ? expx(logx(x) - x) : gamma(x, a, mode);
            after_probe();
            std::cout << id << ' ' << shape << ' ' << mode << ' ' << std::hex << std::setw(16)
                      << std::setfill('0') << std::bit_cast<std::uint64_t>(y) << '\n';
        }
    }
    return !std::cin.eof();
}
