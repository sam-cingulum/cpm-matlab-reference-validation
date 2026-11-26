# V1350 — original-only large-row X\B and robustfit scan (source-disclosed diagnostic)

**Not firstblind. V12 stays SEALED.** The CPM `X\B` and `robustfit` models were measured and certified up to 130 rows and 32 coefficients. Research cohorts need at least 1,000 rows. This run records genuine MATLAB R2026b Update 1 outputs at 131, 200, 256, 257, 400, 512, 513, 768, 1000, 1024, 1025 and 1100 rows, so the model can be scored there and the first kernel that changes can be located.

- `mldivide.bin` (`CPMXB001`): 240 `X\B` problems (1..32 columns, 1..40 right-hand sides, dense and rank-deficient or high-leverage), with `R` and `E` of `qr(X,0)` and MATLAB's reported rank.
- `robustfit.bin` (`CPMRFT01`, the Rust fixture format): 192 default `robustfit(X,y)` cohorts (1..31 predictors, dense and outlier/rank-deficient), `b`, all 17 `stats` fields and the warnings.

Synthetic seeded inputs only (twister seeds 135001–135002). No MEX. Reads no Rust forecast and no earlier MATLAB output. Approved CPUs only: AMD EPYC 7763 or 9V45.
