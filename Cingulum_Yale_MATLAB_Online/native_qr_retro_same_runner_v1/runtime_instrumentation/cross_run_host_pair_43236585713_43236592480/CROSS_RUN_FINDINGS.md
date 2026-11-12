# Genuine MathWorks R2026b cross-host numerical reproducibility: two independent AMD GitHub runners

**Source:** the original MathWorks MATLAB executable, not a MATLAB-compatible replacement. Entire 48-case immutable historical synthetic dataset, three sequential repetitions of every case, real `qr` and original `robustfit` executed in each process. `MKL_CBWR=COMPATIBLE`, `MKL_NUM_THREADS=1`, `OMP_NUM_THREADS=1`, and `maxNumCompThreads(1)`. Original raw input SHA256 `36f70d7cfd31da808f4c5f61f1127e292597097287a21248782723436f26fa1b`.

## Verified independent-host experiment

- [Uninstrumented run 43236585713](https://github.com/sam-cingulum/cpm-matlab-reference-validation/actions/runs/43236585713) on 4-vCPU **AMD EPYC 9V74 80-Core Processor**.
- [Uninstrumented run 43236592480](https://github.com/sam-cingulum/cpm-matlab-reference-validation/actions/runs/43236592480) on 4-vCPU **AMD EPYC 7763 64-Core Processor**.
- Both successfully completed. Their raw complete 144-record result JSONs were byte-identical with SHA256 `d059026575c68ea7b8e879157226e316f4eca65c8590e5ea09176ace44854a97`.
- Both have 48/48 original `robustfit` R matrices bitwise exact across hosts (**192/192 entries**), 48/48 full original leverage vectors (**2,232/2,232**), all 48/48 pivots exact, and 48/48 full public QR R matrices (**192/192 entries**).
- Both used identically hashed MathWorks R2026b executable `65c14851fcf1b43a0dc505567c110acd0c8bb68f8294678a1cef8ca25a244460`, `libmwlapack.so` `8924853d749f3443c1f4f459c6059bd8d94b5befa317b30f95584e5c8a6c2120`, and `mkl.so` `afbb1eb0bf3423ab2b049f10047f1d89de097848ded1dd25db060baf81427d04`.

## Cross-run drift discovered against previous authentic captures

- Previous instrumented original full-48 run [43234972842](https://github.com/sam-cingulum/cpm-matlab-reference-validation/actions/runs/43234972842) produced an equally self-consistent, numerically noninterfering original 48-case MathWorks profile in that run, but against the two new independent hosts only **126/192 public R entries**, **126/192 source R entries**, and **1,203/2,232 source leverage values** are identical. Full-case matches were 7/48 public R, 7/48 source R, 9/48 source h. All pivots matched.
- Earlier 6-case original uninstrumented control [43227210582](https://github.com/sam-cingulum/cpm-matlab-reference-validation/actions/runs/43227210582) matched both new full-48 control hosts **exactly for the overlapping six cases**: 24/24 public R, 24/24 source R, 264/264 h.
- Thus the numerical discrepancy cannot simply be attributed to processing six vs 48 cases. Both distinct CPU models in the new controls reproduced the earlier six-case numeric profile while running the full 48-case workload. Nor can all original MATLAB R2026b execution results be assumed globally identical on unpinned hardware.
- The previous full-48 runner CPU and effective runtime dispatch were **not fingerprinted**, so it would be unjustified to attribute drift specifically to CPU, instruction set, compiler, or any one initialization state. The two new distinct AMD host CPUs demonstrate that CPU model difference **alone** is not sufficient to produce drift.

## Significance

The numerical parity oracle must carry its full original execution-profile provenance. We now have (1) a **48/48 two-independent-host-reproduced original MATLAB reference profile** and (2) separately genuine, internally stable **48-case Householder reflector buffer snapshots** from a different MATLAB numerical profile. Do not compare the latter private buffers against the former as if they belonged to the same exact arithmetic execution.

The MATLAB R/h gate for independently compiled Rust remains unchanged. These 48 cases are historical source-disclosed data, **not a prospective source-unseen validation battery**.
