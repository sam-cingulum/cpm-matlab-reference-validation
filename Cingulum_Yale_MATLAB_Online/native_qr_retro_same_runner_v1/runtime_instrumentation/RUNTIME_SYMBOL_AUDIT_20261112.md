# Targeted genuine MATLAB QR runtime instrumentation, first boundary result

12 November 2026. Research-only synthetic data, no patient records, no modified MathWorks binaries.

- First audit run: https://github.com/sam-cingulum/cpm-matlab-reference-validation/actions/runs/43220453158 . Passive ELF `LD_AUDIT` executed before direct `matlab -batch` but MATLAB exited with **license error -1.2**. This is not numerical evidence. Original runner requires the licensed `matlab-actions/run-command` action.
- Second audit run: https://github.com/sam-cingulum/cpm-matlab-reference-validation/actions/runs/43220857431 . **Licensed genuine MATLAB R2026b executed six QR/robustfit cases** and printed exact R12/R22 bits for each, with a passive loader audit active. The MATLAB action subsequently returned **exit status 255**. The workflow is FAILED, not a certified success; runtime shutdown or audit interaction remains under investigation.
- Both runs uploaded passive loader traces despite failed workflow status. The second run captured ~175 KB of object loads/bindings and a 283-line unique symbol-binding inventory. The original six-case console output is retained in GitHub Actions logs.

## What is observed vs not observed

Dynamic linker symbol binding inventory includes `LAPACKE_dgeqp3`, `LAPACKE_dgeqr2`, `LAPACKE_dgeqrf`, `LAPACKE_dlarfg`, `LAPACKE_dlarfb`, and related BLAS/LAPACK entrypoints in MathWorks `libmwlapack.so` / `mkl.so`. **Bindings are not proof that these functions were called for a given QR operation**. This audit does not yet reveal the actual first-reflector `tau`, the private transformed second-column working buffer, the exact dot reduction tree, or a per-case numerical call trace. Do not infer the QR implementation merely from symbol availability.

Next instrumented step: make MATLAB finish successfully under a loader audit, or run the audit only around a separately licensed MATLAB child process with controlled environment. Then add *call-level* instrumentation to confirmed QR entrypoints and record pre/post buffers, matrix dimensions, exact IEEE-754 values and per-case markers. Avoid collecting MATLAB process secrets or license data; capture only synthetic QR arguments. Validate that instrumented and uninstrumented MATLAB output R/h are bitwise identical. A new prospective source-unseen native certification must remain separate.

The previous complete public-API 48-case capture (run 43219095120) is valid and unchanged. Original native Rust gate remains 163/192 exact R and 1,934/2,232 exact h.
