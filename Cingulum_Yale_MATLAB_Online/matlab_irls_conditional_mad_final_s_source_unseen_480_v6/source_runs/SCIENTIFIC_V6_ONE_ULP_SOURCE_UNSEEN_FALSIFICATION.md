# Genuine MathWorks R2026b V6: exact 480 new raw fits and 1-ULP precommitted Rust MAD failure

## Original independent pre-oracle freeze

The original source never saw the NEW 480-case raw x/y cohort until the independent pure Rust Q/R/h/Qy/initial OLS forecast was committed and pushed at private SHA `ed91627e77be072bbb5b7cd6760c16f80a417403`. SHA256 raw dataset `b0f80f32ebc8ba855b282a12fde5b0d2e46a9152f747695760cc090589884ec5`, SHA256 frozen complete upstream numeric forecast `85ebe059b709359ad162d95d2394ddf8850309083686596615d06b5d0260eb50`. The two source-conditional arithmetic algorithms for final `mad_s` and `s` were likewise precommitted in pure Rust before original MathWorks execution. **Source final beta and source robust_s remained given conditional inputs**, NOT independently predicted by pure Rust.

Four genuine licensed unmodified MathWorks R2026b `qr` and `robustfit` runs completed normally. The untouched original MATLAB source was repeated 3x per host and independently repeated 3x under read-only QR buffer instrumentation, with **bitwise identical original final fields and all original QR buffer events**. Original SHA256 and gzip archive SHA256 manifests are stored per run, including original CPU, `MATLAB`, `libmwlapack.so` and `mkl.so` checksums. No original MathWorks proprietary binaries are redistributed.

| Original source run | Original host CPU | Independently frozen Rust QR/h/Qy/ols_s | Original source-conditional final MAD | Original source-conditional final s |
|---|---|---|---|---|
| [43314464335](https://github.com/sam-cingulum/cpm-matlab-reference-validation/actions/runs/43314464335) | AMD EPYC 7763 | **480/480** | **479/480, FAILED** | **480/480** |
| [43314468307](https://github.com/sam-cingulum/cpm-matlab-reference-validation/actions/runs/43314468307) | AMD EPYC 9V45 | **480/480** | **479/480, FAILED** | **480/480** |
| [43314454388](https://github.com/sam-cingulum/cpm-matlab-reference-validation/actions/runs/43314454388) | Intel Xeon Platinum 8573C | Different vendor floating-point profile, AMD model NOT certified | Not a compatible AMD model | Not a compatible AMD model |
| [43314459555](https://github.com/sam-cingulum/cpm-matlab-reference-validation/actions/runs/43314459555) | Intel Xeon 6975P-C | Different vendor floating-point profile, AMD model NOT certified | Not a compatible AMD model | Not a compatible AMD model |

## One-ULP original source falsification and *retrospective* repair

Only original unseen case `matlab_irls_conditional_unseen480_tiny_rep6_n11_seed202611139313` failed the AMD original source MAD comparison. Real MathWorks result `3fd19e341645f13f`; independently precommitted Rust result `3fd19e341645f13e`, precisely one IEEE754 ULP. Both use source original final beta and independently previously frozen exact Rust leverage. Binary64 values for source final residuals, original h and raw input are separately verified. The failing numerical structure was the median of two central remaining residual magnitudes after dropping the single smallest absolute adjusted residual: original MathWorks is consistent with `lower + (upper - lower) / 2` rather than `(lower + upper) / 2`.

**Scientific chronology:** Only AFTER examining this original source failure did the Rust implementation change the even-median association. Its repaired code reproduces this original source value and 480/480 original AMD MAD values retrospectively on this V6 set and 480/480 historical V5 fits. This does NOT erase or upgrade the original precommitted V6 479/480 outcome. A completely NEW odd-length-enriched V7 input set and frozen corrected Rust source was committed privately at `5ad7a6be550026c769eeadbed9cb446a5afcff10` **before** launching a new authentic MATLAB R2026b oracle; the V7 result must be judged separately.

Further original `stats.w` evidence is a separate **failed shortcut**: on prior original MATLAB V5 source, bisquare weights recomputed naively from source final reported beta, final MAD and independently frozen leverage match just **9/480 complete weights**. Thus original IRLS iteration-state arithmetic, final robust coefficients and robust_s remain unresolved. Neither conditional upstream result establishes original end-to-end raw robustfit or any of the four complete Yale OHBM CPM modes.
