# Genuine R2026b original QR R12 isolated to vendor BLAS matrix-vector reduction

**Authentic original MathWorks execution** [GitHub run 43249881892](https://github.com/sam-cingulum/cpm-matlab-reference-validation/actions/runs/43249881892). Original `DGEQP3` and robustfit source are unmodified. All 144 R, leverage h and pivot records exactly match the separately run uninstrumented original MATLAB control, with normal process exit.

The probe observes 288 original, source-identified `DGEQP3` executions across 48 distinct synthetic raw-x cases times three repetitions of public `qr` and unchanged `robustfit`. After each **genuine original `DGEQP3` call has completed**, the original first Householder column/tau is copied into scratch memory and passed to the SAME bundled MathWorks `DLARF` and `DGEMV` numerical functions, with the original raw second column. Nothing is written into any MATLAB-owned input or output buffer after original QR completion.

| Independently recomputed using bundled original numerical routine | Exact original `R12` cases |
|---|---:|
| `DLARF` scratch Householder update | **48/48** |
| `DGEMV` scratch dot + standard Householder top-row update | **48/48** |
| `DDOT` scratch dot + same update | **22/48** |

All 288 events repeat bitwise per original case, source pair identifiers and original R12 match, and the capture has zero overflows. The exact **vendor `DGEMV` dot-product bits**, original R12, tau1, raw x, the provenance of numerical library and CPU, plus case-level results are archived here. MathWorks library fingerprint and CPU AMD EPYC 9V74 match the separately reproduced earlier AMD source profile (control JSON SHA256 `d059026575c68ea7b8e879157226e316f4eca65c8590e5ea09176ace44854a97`).

**Newly established:** the original `DGEQP3` second-column top-row result is exactly reproduced by `DGEMV` dot and subsequent reflector application on the same original numerical runtime, whereas substituting a mathematically equivalent vendor `DDOT` does NOT preserve binary64 parity. Native pure Rust must implement this exact BLAS-specific reduction tree; mathematical dot-product identity or more precision is insufficient. This is original-vendor **diagnostic** parity only, not compiled independent Rust R12/full QR certification.

An earlier instrumented run 43249130345 failed its verifier because the wrapper mistakenly captured LAPACK `lwork=-1` workspace-only queries (which have `tau=0` and unset pivots). The actual numerical output itself matched the uninstrumented original; the real-call filtering defect was corrected with explicit `lwork >= 1` before the passing run.
