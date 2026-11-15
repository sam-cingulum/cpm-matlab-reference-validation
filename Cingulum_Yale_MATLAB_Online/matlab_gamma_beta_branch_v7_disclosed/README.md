# MATLAB R2026b genuine original numerical branch probe V7 (explicitly source-disclosed)

**Purpose:** Determine original vendor `gammaln`, `betaln`, `betainc` upper/lower and Student-t numerical bit behaviour independently of the original Yale/CPM source-unseen certifications.

All 1,505 (320 gamma, 887 beta, 298 Student-t) deliberately disclosed synthetic numeric arguments are published and SHA-locked **before** executing original MathWorks R2026b. No confidential, patient, V11 unseen source, or MATLAB-output data appear in `input.json`. This is not original-source-unseen V12. V12 remains `NOT_GENERATED`.

The input design is domain-based rather than original-bit-selected: ±2 ULP around positive half-/whole-integer and fractional gamma values; ±1 ULP around the mean and Numerical Recipes incomplete-beta fraction thresholds for 60 parameter pairs; Student-t values at df 3–37, near `t*t==df` and tails. Unlike earlier V2, many gamma anchors and Student-t degrees are new.

Recreate published raw input with `python3 generate_disclosed_inputs_v7.py`, check `sha256sum -c input.sha256`, run `python3 -m unittest discover -s . -p test_disclosed_v7_verifier.py`. All original functions in `run_original_gamma_beta_branch_v7_disclosed.m` use unchanged genuine builtins `gammaln`, `gamma`, `betaln`, `betainc`, `tcdf` and elementary arithmetic. The GitHub workflow must fail closed before invoking MATLAB unless CPU is AMD EPYC 7763/9V45/9V74 and input SHA matches; it sets MathWorks R2026b, `MKL_CBWR=COMPATIBLE`, and one thread. It checks two exact repetitions and hashes complete original output and vendor/CPU fingerprints. GitHub artifacts must later be preserved permanently via SHA-checked public source archives rather than relying on 90-day Actions artifacts.

Original source execution requires precommitted, original-blind *native Rust* V7 forecasts generated from the same disclosed `input.json`; commit forecast SHA to private Rust before any original source run. This prevents inadvertent post-source numerical tuning masquerading as preoracle prediction. The probe is nonetheless **source-disclosed** and no result may be called source-unseen certification.

The next mathematical investigation is half-integer gamma log-product/log-sum evaluation order and incomplete-beta upper/lower non-equivalence, with the original MATLAB output used only by the scorer. Preserve every failed alternative, exact p acceptance gate 1,920/1,920, and separate original Yale-compatible and mathematically corrected paths.
