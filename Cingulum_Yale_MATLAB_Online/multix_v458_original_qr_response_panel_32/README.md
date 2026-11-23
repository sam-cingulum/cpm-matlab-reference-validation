# V458 — causal original MATLAB QR response-panel width and factorization reuse

**SOURCE-DISCLOSED genuine MathWorks R2026b Update 1 only. Not a new Rust parity acceptance. Comprehensive V12 SEALED.**

## Primary question
V457: `decomposition(X,'qr')\B` reproduces original dense MATLAB `X\B` on all 116,928 source-disclosed raw coefficients, whereas `R\(Q'*B)` reproduces only 111,022/116,928. The primary unresolved question is whether this is an **RHS application / GEMM panel kernel difference** rather than numerical differences from refactorization, public Q assembly or triangular backsolve.

For each original X, build and reuse **one** QR decomposition object at each padding setting, and solve the *same* RHS at widths from 1 to 32, including 11→12, 12→13, 23→24 and 24→25. Compare:
- default `X\B`;
- same cached `D=decomposition(X,'qr'); D\B`;
- explicit `R\(Q'*B)`;
- individual `D\B(:,j)` for the same selected physical columns, with **the identical decomposition object** (no refactorization).
Only first two original coefficient raw IEEE binary64 words are archived; the remainder previously remained invariant under padding in the original two-reflector source geometry.

## Causal controls
- The 96 independent X/B probes are read directly from frozen original-only V449 input SHA **`e2fc94a01754901a2ff9da73f6b4f479857c126e5ce71e962e66fe0b92d4c079`**, without consulting genuine MATLAB numerical results or independently compiled Rust outputs.
- Two source-only response layouts per probe: `repeated` (strict cross-archive overlap with V456 on widths 1,12,16); `signed_power2` (column-j scaled by the exact power of two `2^(mod(j-1,5)-2)` and sign negated for even j). Does not hard-code any oracle numerical value.
- Zero padding `n48: z=0,2,3,7`; `n65: z=0,1,2,7`. Factorization D is cached per pad and reused for every RHS width and single-column probe. The same row support, factorization and response values are used in each contrast.
- Widths `[1,2,11,12,13,16,17,20,23,24,25,28,32]`. 96 cases × 4 z × 2 layouts × 13 widths = 9,984 full panel comparisons per original execution. Two exact original repetitions are required.
- Original X and Y are *dense*, full rank. Never treat two-input sparse `qr(S,B)` as dense `D\B` evidence.
- CPU gate fail-closed accepts only AMD EPYC 7763/9V45; pinned MathWorks library, MKL compatibility, one thread and raw CPU/runtime provenance.
- Matching outputs are original MathWorks to original MathWorks, **not** native Rust.
- The MATLAB `decomposition` class does not expose its private QR factors through a supported public API; comparison of public methods cannot uniquely prove internal low-level BLAS kernel identity.

## Acceptance
Strict bit equality for all paired cached-vs-hidden original results and independent AMD runs. Cross-archive V456 raw hidden/decomp bits at repeated widths 1,12,16 are independently mandatory, *not* used to fit the original V458 source. Record all differences at other RHS widths without retrofitting source or weakening 0-bit thresholds.

This original-only experiment is intended to generate a falsifiable physical column-panel dispatch model for a future **independently compiled Rust implementation**. Until Rust reproduces the full frozen original cohorts and original-firstblind tests, V12 remains **SEALED**.
