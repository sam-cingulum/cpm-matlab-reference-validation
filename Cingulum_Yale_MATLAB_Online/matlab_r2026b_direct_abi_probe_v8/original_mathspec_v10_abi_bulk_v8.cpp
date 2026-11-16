// User-authored research-only scalar ABI bridge, run only on an
// authenticated genuine MathWorks MATLAB R2026b installation.
// Never used in independent Rust. No proprietary object code redistributed.
#include <cstdio>
#include <cstdlib>
#include <cstdint>
#include <cstring>
#include <dlfcn.h>
#include <iostream>
#include <iomanip>
#include <string>
#include <cmath>
static double from_hex(std::string h) {
  if (h.size()!=16) std::exit(3);
  std::uint64_t bits=std::strtoull(h.c_str(),nullptr,16);
  double out;
  static_assert(sizeof(bits)==sizeof(out));
  std::memcpy(&out,&bits,sizeof(out));
  return out;
}
static std::string to_hex(double x) {
  std::uint64_t u;
  std::memcpy(&u,&x,sizeof(x));
  char buffer[17];
  std::snprintf(buffer,sizeof(buffer),"%016llx",static_cast<unsigned long long>(u));
  return std::string(buffer);
}
int main(int argc,char**argv) {
  if (argc!=4) {
    std::fprintf(stderr,"usage: original_mathspec_v8 LIB GAMMA_MANGLED BETA_MANGLED\n");
    return 2;
  }
  void* lib=dlopen(argv[1],RTLD_NOW|RTLD_LOCAL);
  if(!lib){std::fprintf(stderr,"dlopen unavailable %s\n",dlerror());return 3;}
  using Gamma=double(*)(double);
  using Beta=double(*)(double,double,double,int);
  auto gamma=reinterpret_cast<Gamma>(dlsym(lib,argv[2]));
  auto beta=reinterpret_cast<Beta>(dlsym(lib,argv[3]));
  if (!gamma||!beta){std::fprintf(stderr,"ABI symbol unavailable\n");return 4;}
  std::string mode,xh,ah,bh;
  while(std::cin>>mode) {
    if(mode=="G") {
      if(!(std::cin>>xh))return 5;
      double x=from_hex(xh);
      volatile double ans=gamma(x);
      std::cout<<"G "<<xh<<" "<<to_hex(ans)<<'\n';
    } else if(mode=="B") {
      if(!(std::cin>>xh>>ah>>bh))return 6;
      double x=from_hex(xh),a=from_hex(ah),b=from_hex(bh);
      volatile double v0=beta(x,a,b,0);
      volatile double v1=beta(x,a,b,1);
      std::cout<<"B "<<xh<<" "<<ah<<" "<<bh<<" "<<to_hex(v0)<<" "<<to_hex(v1)<<'\n';
    } else return 7;
  }
  dlclose(lib);
  return 0;
}
