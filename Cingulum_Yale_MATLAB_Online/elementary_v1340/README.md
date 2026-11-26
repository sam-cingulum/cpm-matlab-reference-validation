# V1340 — original-only elementary-function probe (source-disclosed diagnostic)

**Not firstblind. V12 stays SEALED.**

Why: in the V1330 firstblind (`robustfit_v1330_firstblind/`), 20 of 499 p-values at exactly one error degree of freedom differed by 1–2 ulp from a Cauchy model that uses glibc `atan`. After that audit, on the disclosed outputs, an fdlibm-style `atan` reproduced all 499. This probe checks that model against genuine MATLAB R2026b Update 1 over every fdlibm reduction interval, and records the other elementary and special functions the CPM engine uses, so later work starts from measured values.

What it dumps (container `CPMEF001`: magic, uint64 n, uint64 m, then the first input, the second input, the result):
- `atan`, `acot`, `tcdf(-a,1)`, `2*tcdf(-|a|,1)`, `tcdf(a,1)`; scalar-versus-vector and array-length checks in `log.txt`.
- `exp`, `log`, `log1p`, `expm1`, `sqrt`, `sin`, `cos`, `tan`, `asin`, `acos`, `sinh`, `cosh`, `tanh`, `gammaln`, `gamma`, `erf`, `erfc`, `atan2`, `power`, `hypot`.
- `tcdf(-a,nu)` for nu = 1..8 and `betainc` (lower and upper) for eleven (a, b) pairs.
- Short excerpts (matching lines only) of `tcdf.m`, `acot.m` and `robustfit.m`, and which shipped libraries export arctangent symbols.

Synthetic seeded inputs only (twister seeds 134001–134003). No MEX. Reads no Rust forecast and no earlier MATLAB output. Approved CPUs only: AMD EPYC 7763 or 9V45.
