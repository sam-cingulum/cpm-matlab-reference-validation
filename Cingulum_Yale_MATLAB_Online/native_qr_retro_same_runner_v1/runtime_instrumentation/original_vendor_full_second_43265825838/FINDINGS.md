# Genuine MathWorks R2026b complete original second Householder numerical factorization

Original [licensed R2026b run 43265825838](https://github.com/sam-cingulum/cpm-matlab-reference-validation/actions/runs/43265825838) on AMD EPYC 9V45, original compiled `mkl.so` and unmodified `DGEQP3`/`robustfit`. Input 320 fresh binary64 cases with exact raw x/y input SHA256 `b03922f51ae9c5edc2bec7f68df01979d8f915ec0d8467179bbd580fa9871efe`. The true original MATLAB QR R/pivots, source robustfit R/h/beta and *all* double-valued source statistics were precisely bitwise identical across **960 uninstrumented and 960 instrumented original result records**. No source modification, no exit error and zero instrumentation overflow.

After each genuine original `DGEQP3` returns, a wrapper isolates the original first Householder tail and tau1 and recomputes the original second column entirely on private scratch buffers using its own unmodified source `DLARF`, then invokes the real vendor `DLARFG` on the remaining `n-1` scratch tail. The scratch `DLARF` matrix **before** the second reflector (`DLARF_UPDATE_HEX`) and the entire scratch array after `DLARFG` (`DLARFG_FINAL_HEX`), and original MATLAB's second matrix (`SECOND_A_HEX`) are all saved in hex. Complete original original 320 source cases, six exact repeated events per case, all 1,920 original vendor stage observations stable.

**True source-to-vendor exact result:**

| Vendor-scratch result vs original unchanged full QR | Exact |
|---|---:|
| R12 | **320/320** |
| R22 | **320/320** |
| second Householder tau2 | **320/320** |
| all second Householder tails | **320/320** |
| complete second-column working matrix | **320/320** |
| each binary64 second-column value | **16,056/16,056** |

This is **complete vendor numerical composition**, NOT yet independent compiled pure-Rust parity for these stages. It reduces the native algorithmic gap to the precise original `DLARF` per-element update and original `DLARFG` norm, beta, tau, and tail scaling. Original source-sha input, original library/CPU fingerprints and original uninstrumented control are preserved with raw stage matrices and their SHA256 manifest. No MathWorks binary copied, altered or redistributed.
