function [lower,upper,gammaln_a] = matlab_original_kernel_codegen_entry_v1(x,a,b)
%#codegen
% Contract-only MINIMAL SCALAR numerical entrypoint for licensed MATLAB Coder.
% This is NOT a replacement for original MATLAB or independent Rust.
% Inputs must be scalar real finite double, 0<x<1 and a,b>0.
% No original numerical oracle samples or case-specific output bits.
assert(isa(x,'double') && isscalar(x));
assert(isa(a,'double') && isscalar(a));
assert(isa(b,'double') && isscalar(b));
lower = betainc(x,a,b,'lower');
upper = betainc(x,a,b,'upper');
gammaln_a = gammaln(a);
end
