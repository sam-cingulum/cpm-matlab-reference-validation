# Independent R2026b source-unseen raw robustfit certification

**Verdict:** prospective complete 48/48 full-field **binary64 exact** within genuine MathWorks MATLAB R2026b Update 1. **Not** source-free *compiled Rust* original binary64 identity; not universal cross-platform/clinical validation.

## Frozen evidence chain

| Stage | Public Git revision or actual licensed run | Scope |
| --- | --- | --- |
| First frozen preregistration | `d48a5a4` | 48 original-source-unseen x/y cohorts, exact 12-field gates, separate Stage A/B code |
| Corrected numeric-environment preflight | `bd05c9b` | Explicitly capture actual MATLAB R2026b environment; no change to acceptance thresholds |
| Clone-only original-source-blind forecasts | [Run 43177058314](https://github.com/sam-cingulum/cpm-matlab-reference-validation/actions/runs/43177058314) at `bd05c9b` | Source-free independent raw x/y clone only |
| Immutable public forecast commit **before original run** | `bceb1a7` | Clone forecast SHA-256 `435000a897ab50b5443ff88cc17ed76431d7f9c881d3ad5e3d4c5fd81ad9eaac` and code SHA manifest |
| Unchanged original `robustfit` and external verifier | [Run 43177440479](https://github.com/sam-cingulum/cpm-matlab-reference-validation/actions/runs/43177440479) at `bceb1a7` | Original-only computation on frozen inputs; independent Python verifier ran afterwards |
| Original output artifact SHA-256 | `02f4a8c7aba7c3ee65b37bc3873d3a603c06382272a7b8e21075f7a6d933e6b5` | `source_result.json` from licensed run |
| Exact verdict SHA-256 | `e6f5706e1d74a3803e97b6848bab009ecf2759a702f9a240765450ff89dc4271` | `strict_external_verdict.json`, identical when recomputed locally |

Input SHA-256: `36f70d7cfd31da808f4c5f61f1127e292597097287a21248782723436f26fa1b`.

## Exact original-source comparison

| Strict field | Exact cases |
| --- | --- |
| Full QR R, 4 entries each | 48/48 |
| Full leverage h, every observation | 48/48 |
| Last IRLS weight vector w, every observation | 48/48 |
| Intercept | 48/48 |
| Slope | 48/48 |
| Final MAD | 48/48 |
| Robust scale robust_s | 48/48 |
| Initial OLS scale ols_s | 48/48 |
| Blended effective scale s | 48/48 |
| Slope t-statistic | 48/48 |
| Slope p-value | 48/48 |
| Weight callback count | 48/48 |

**Total:** 576/576 field-case gates; 5,088/5,088 individual float64 hex values, counting all 2,232 leverage elements, all 2,232 weight elements, all 192 QR entries and 432 other scalar values. Absolutely no epsilon threshold.

Both independent and original executions recorded identical observed MATLAB R2026b Update 1 versions, AMD EPYC 9V74 CPU model, Linux architecture, `MKL_CBWR=COMPATIBLE`, `OMP_NUM_THREADS=1`, `maxNumCompThreads(1)`, and the same observed empty internal `MKL_NUM_THREADS` value (the GitHub environment had required `MKL_NUM_THREADS=1` before launching MATLAB). The identical-runtime-profile gate was mandatory and passed.

The original-source outputs were not available when the clone-only predictions and their SHA256 were publicly frozen. The after-original independent local recheck reproduced the exact CI verdict. A 9-test adversarial verifier battery included flipped bits, missing/reordered cases, truncated arrays, absent fields, changed input hashes and unpinned CPU settings.

## What this does NOT establish

- Does not show compiled Rust `raw x/y → R, h, w, beta, t, p` exact original MATLAB bits. Rust 1,032/1,032 conditional leverage still requires original-supplied R, and native raw QR is not exact.
- Does not verify all possible input shapes, all MathWorks releases or all CPU dispatch profiles; source R/h have shown variation across previous genuine MATLAB CI executions with different profiles.
- Does not certify complete Yale OHBM option-3 original leave-one-out prediction bits, nor the broader Yale original script family or clinical use.
- Does not imply anything about accessing MathWorks proprietary source; the original `robustfit` implementation was unchanged.

Future native candidates **cannot inspect or tune against these original-source outputs and then call these same 48 cases a prospective holdout**. New native source-unseen certifications require separately sealed predictions and new preregistered inputs.
