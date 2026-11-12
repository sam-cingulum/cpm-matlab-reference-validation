# Genuine source-unseen original MathWorks R2026b robustfit initial OLS scale from independent compiled Rust

**New genuine prospective result:** The original R2026b `robustfit` initial **`ols_s`** numerical value is independently reconstructed to **bit-for-bit IEEE754 binary64 identity** from raw x/y by compiled pure Rust on 480 entirely new input cases, on three independently executed authentic licensed MathWorks AMD hosts, while preserving a genuine source Intel negative control.

## Strict source-unseen chronology

- 480 **entirely new raw binary64** inputs, 12 tested predictor lengths × 40 independent numerical replicates, original input exact SHA256 `0e098e490c9baa14eca8614e24c4aa278c7536ed18129e64e80114f4d1f50430`.
- Complete pure Rust full-QR/Q/R/original leverage h, original Qy and original initial OLS scale numerical predictions SHA256 `362b874b9680c0e7d22990e90fd845278e65762f90f246294a87f7f4640ccaf9`, **committed and pushed at private SHA `de552a6421b06c5c2288e1a986df6d08291dfbaf` BEFORE any original MATLAB numerical execution of this input**.
- The Rust OLS coefficient system solves the true, independently reconstructed coefficient-ordered QR R against source-independently predicted Qy, preserving upper/lower triangular orientation and strict operation order. Initial residual evaluation is `y - (intercept + slope*x)` with separately rounded products/addition, original LAPACK-stable scaled norm, then direct division by `sqrt(n-2)`. Unlike a plain sum of squares or rearranged norm division, the exact binary64 structure was verified source-disclosed before prospective numeric freeze.
- No original MATLAB or proprietary numerical intermediate is supplied to Rust for these upstream predictions. Original MathWorks uses *unmodified* `robustfit(x,y)` and `qr`, not substituted Rust or simulated oracles.

## Genuine original MATLAB R2026b source-run strict results

| Original licensed MATLAB source | CPU | Complete QR/Q/R/h/Qy/**ols_s** fields source-unseen bit exact | Original `ols_s` bit exact |
|---|---|---:|---:|
| [43305620278](https://github.com/sam-cingulum/cpm-matlab-reference-validation/actions/runs/43305620278) | AMD EPYC 7763 | **480/480** | **480/480** |
| [43305626186](https://github.com/sam-cingulum/cpm-matlab-reference-validation/actions/runs/43305626186) | AMD EPYC 9V74 | **480/480** | **480/480** |
| [43305636922](https://github.com/sam-cingulum/cpm-matlab-reference-validation/actions/runs/43305636922) | AMD EPYC 7763 | **480/480** | **480/480** |
| [43305631797](https://github.com/sam-cingulum/cpm-matlab-reference-validation/actions/runs/43305631797) | **Intel Xeon 6975P-C** | **4/480 AMD-profile failure** | **218/480 AMD-profile failure** |

Each authentic MATLAB host executed all 480 real raw binary64 cases **three times uninstrumented plus three times read-only instrumented**. All original source numeric fields including `ols_s`, Qy, original `robust_s`, final beta/s, h, residual and inference fields are **bitwise unchanged** by instrumentation; all original vendor QR private-buffer events repeated sixfold exactly, 2,880 original events per host, no original robustfit errors, no source capture overflow, normal execution. The AMD full Q also matches independent compiled Rust **16,960/16,960 IEEE754 values per host**, original leverage h **8,480/8,480**, original Qy **960/960** and original `ols_s` **480/480**. Combined three-host totals are **1,440/1,440 complete full-field cases**, Q **50,880/50,880**, h **25,440/25,440**, Qy **2,880/2,880** and original initial `ols_s` **1,440/1,440** bitwise source exact.

The source original Intel CPU produced a different, internally repeatable genuine MATLAB profile. The frozen AMD pure Rust model matched only **4/480 complete chain cases**; it was expressly NOT marked as passing via numerical tolerances.

## Original evidence and scientific boundary

Original full numerical outputs, original private QR in-place buffers, original repeated and captured MATLAB source, vendor executable hashes, strict source noninterference gates and complete original and archived SHA256 manifests are preserved losslessly in each source-run folder. Machine certification in private research project is `python3 tests/matlab_free/replay_source_unseen_native_Rust_Qy_OLS_S_480_v5_from_archived_bytes.py`. It verifies archived/uncompressed SHA256 and all original source numerical noninterference, replays exact compiled Rust comparison against the independently frozen forecast and **requires 3 AMD complete exact hosts plus genuine failed Intel negative control**. All source original bytes are retained, no proprietary MATLAB executable redistributed.

**This is NOT complete original MATLAB `robustfit` or Yale CPM parity.** Original full IRLS iterative robust regression beta, MAD/`robust_s`, final s, weighted LS iterations, final coefficient covariance and inference still require rigorous independent raw-input/source-unseen binary64 implementation. Original `ols_s` is now prospectively certified for these **12** observed lengths and **AMD** source profiles only. Original source defects / compatibility must remain separate from scientifically corrected production algorithms.
