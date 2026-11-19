// Reference-only probe for the installed public numerical ABI and host libm.
// Inputs and outputs are publicly reproducible mathematical function values.
#include <bit>
#include <cmath>
#include <cstdint>
#include <cstdlib>
#include <dlfcn.h>
#include <iomanip>
#include <iostream>
#include <string>

int main(int argc, char** argv) {
    if (argc != 3) return 2;
    void* lib = dlopen(argv[1], RTLD_NOW | RTLD_LOCAL);
    if (!lib) return 3;
    using Gamma = double (*)(double, double, int);
    auto gamma = reinterpret_cast<Gamma>(dlsym(lib, argv[2]));
    if (!gamma) return 4;
    std::string id;
    std::cout << std::hex << std::setfill('0');
    while (std::cin >> id) {
        if (id.size() != 16) return 5;
        const double x = std::bit_cast<double>(std::stoull(id, nullptr, 16));
        const double logx = std::log(x);
        const double scale = std::exp(logx-x);
        std::cout << id;
        for (double a : {logx,scale,gamma(x,1.,0),gamma(x,1.,1),
                         gamma(1.,x,0),gamma(1.,x,1)})
            std::cout << ' ' << std::setw(16) << std::bit_cast<std::uint64_t>(a);
        std::cout << '\n';
    }
    return !std::cin.eof();
}
