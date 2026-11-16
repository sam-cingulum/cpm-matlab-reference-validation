// Source-disclosed research: genuinely-independent native Rust V11 t/dfe
// go into MathWorks R2026b's ORIGINAL beta ABI, and only in the authenticated
// MATLAB runner. The original licensed proprietary library is NOT linked,
// shipped, embedded or called by Cingulum's independent pure-Rust product.
#include <cstdio>
#include <cstdlib>
#include <cstdint>
#include <cstring>
#include <cmath>
#include <dlfcn.h>
#include <iostream>
#include <string>
static double from_hex(const std::string& h) {
    if(h.size()!=16) std::exit(3);
    std::uint64_t u=std::strtoull(h.c_str(),nullptr,16);
    double x;
    std::memcpy(&x,&u,sizeof(x));
    return x;
}
static std::string to_hex(double x) {
    std::uint64_t u;
    std::memcpy(&u,&x,sizeof(x));
    char s[17];
    std::snprintf(s,sizeof(s),"%016llx",static_cast<unsigned long long>(u));
    return std::string(s);
}
int main(int argc,char**argv) {
    if(argc!=3) {
        std::fprintf(stderr,"usage: mathworks_v11_original_research LIB BETA_MANGLED\n");
        return 2;
    }
    void* lib=dlopen(argv[1],RTLD_NOW|RTLD_LOCAL);
    if(!lib){std::fprintf(stderr,"dlopen: %s\n",dlerror());return 3;}
    using Beta=double(*)(double,double,double,int);
    auto beta=reinterpret_cast<Beta>(dlsym(lib,argv[2]));
    if(!beta){std::fprintf(stderr,"betainc not available\n");return 4;}
    std::string type,id,th,dfh;
    int index;
    while(std::cin>>type>>id>>index>>th>>dfh) {
        if(type!="T" || index<1 || index>2)return 5;
        double t=from_hex(th),df=from_hex(dfh);
        if(!(std::isfinite(t)&&std::isfinite(df)&&df>0.0))return 6;
        // One fixed mathematical policy for EVERY case. No answer-dependent
        // ULP choices or branch-overfit are permitted.
        double t_abs=std::fabs(t);
        double t2=t_abs*t_abs;
        double den=df+t2;
        double x=df/den;
        double u=t2/den;
        double halfdf=df/2.0;
        volatile double lower=beta(x,halfdf,0.5,0);
        volatile double upper=beta(u,0.5,halfdf,1);
        volatile double selected=(t2<df)?upper:lower;
        std::cout<<"T "<<id<<" "<<index<<" "<<th<<" "<<dfh
                 <<" "<<to_hex(selected)<<" "<<to_hex(lower)
                 <<" "<<to_hex(upper)<<'\n';
    }
    dlclose(lib);
    return 0;
}
