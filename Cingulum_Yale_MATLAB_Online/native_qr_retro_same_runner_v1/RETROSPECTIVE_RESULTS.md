# Retrospective same-runner original MathWorks R2026b vs compiled source-free Rust QR

**12 November 2026. Original MATLAB R2026b Update 1 source: genuine unchanged MathWorks `robustfit`, public `qr` API. This is strictly retrospective on the ALREADY disclosed 48 synthetic x/y cohorts, not a new source-unseen prospective or native Rust certification.**

## Source provenance

- Historical independently source-unseen full MATLAB-language exact `robustfit` 48-case certificate: [original source run 43177440479](https://github.com/sam-cingulum/cpm-matlab-reference-validation/actions/runs/43177440479), pinned at `bceb1a7`.
- Same-runner native Rust compiled and raw R predicted **before** invoking original MATLAB: [run 43181373473](https://github.com/sam-cingulum/cpm-matlab-reference-validation/actions/runs/43181373473), source revision `af22bc0839d5f165911f57e4bc3389faf982fb1a`. This was an experimental research ordering, **not a public-before-oracle commit of new hidden Rust predictions**, because the originals were already disclosed.
- Original public QR and Householder/norm/dot/sum black-box arithmetic: [run 43182539905](https://github.com/sam-cingulum/cpm-matlab-reference-validation/actions/runs/43182539905), revision `e3a2477b38ff6b298a4cd4d321f0677a7042eff5`.
- Frozen original raw input SHA-256: `36f70d7cfd31da808f4c5f61f1127e292597097287a21248782723436f26fa1b`.
- Authenticated original 48-case source result SHA-256: `02f4a8c7aba7c3ee65b37bc3873d3a603c06382272a7b8e21075f7a6d933e6b5`.

## Independently reverified same-runner comparisons

| Exact binary64 gate | Verified |
| --- | ---: |
| Native Rust input x bitwise identical to MathWorks `jsondecode` x | 48/48 entire vectors |
| Original unchanged `robustfit` R matches public `qr` R on same runner | 48/48 entire matrices |
| Original MathWorks R on AMD EPYC 9V74 vs different AMD EPYC 9V45 host under COMPATIBLE | **192/192 full R elements, 48/48 whole matrices** |
| Source-free native Rust QR pivot orientations | 48/48 |
| Pure Rust QR R vs genuine original on same AMD runner | **123/192 entries, 5/48 whole matrices** |
| Separate pure Rust product QR on local Intel vs publicly compiled Rust test on AMD | **192/192 identical native R outputs** |

The AMD experiments used the same MATLAB R2026b Update 1, `MKL_CBWR=COMPATIBLE`, `OMP_NUM_THREADS=1`, and `maxNumCompThreads(1)`. The specific source profiles were AMD EPYC 9V74 and AMD EPYC 9V45. This establishes two-profile stability on these 48 cases only, not universal portability.

The native Rust source-free probe was compiled from independently authored Rust without extracting MathWorks code, with explicit x86-64 target and FMA disabled. The private Rust code computes `R, Qᵀy, beta0` and is not wired into production fitting. On the same disclosed 48 cases, the private raw QR + Rust leverage path reproduces **992/2232 source h bits, 8/48 entire h vectors**.

## Additional independent MKL/Rust backend result (local research, also retrospective)

A separate independently compiled Rust research program uses Intel oneAPI MKL's standard publicly documented `LAPACKE_dgeqp3` for **raw x → R**, then the separate pure Rust `source_conditional_leverage(raw x, independently obtained R)`. It does not pass source reported R/h to either numerical algorithm.

Under local Intel Core Ultra 7 / oneAPI MKL 2026, `MKL_CBWR=COMPATIBLE`, `MKL_NUM_THREADS=1`, `OMP_NUM_THREADS=1`, the result on the same 48 previously disclosed cases was:

- **155/192** original R entries, **17/48** whole R matrices.
- **1841/2232** original h entries, **19/48** whole h vectors.
- **48/48** pivot orientations.

This is a substantial retrospective native research improvement, but **not complete bitwise original R/h** and **not prospective source-unseen certification**. Because the vendor MKL implementation and original source ran on different CPUs, a future same-host / genuinely prospective fixed-profile test is required before any original-source exactness claim.

## Public MATLAB numerical operation-order forensics

Run 43182539905 examined 13 public MATLAB scalar candidates against the actual `qr(X,'econ','vector')` pivoted R. The highest three-term Householder predictor matched only **21/48** original R12 values; `-sign(alpha)*norm(first_column)` matched only **27/48** original R11 values. Other `Q' * x`, `dot`, `sum`, and independent Householder combinations likewise did not universally reproduce QR's bit patterns. This isolates rounding and BLAS-level operation order as genuine obstacles, not data transport or incorrect pivot selection.

Raw original R12 arithmetic is **not** certified by a 1e-12 numerical approximation or by picking a candidate expression after inspecting source outputs.

## Artifact and tamper verification

The `evidence/` directory contains both original, native and numerical candidate outputs with byte-for-byte SHA256 anchors in `verify_archived_evidence.py`. Run:

```bash
python3 Cingulum_Yale_MATLAB_Online/native_qr_retro_same_runner_v1/verify_archived_evidence.py
python3 -m unittest discover -s Cingulum_Yale_MATLAB_Online/native_qr_retro_same_runner_v1 -p test_verify_archived_evidence.py -v
```

The verifier requires source manifest SHA, original run IDs, 48 case IDs, matching 48 full binary64 raw-input vectors, 48 source API QR comparisons, 192/192 cross-AMD original R stability, exact native mismatches and 13 method counts. One-bit evidence corruption fails closed.

**Next milestone:** reconstruct the actual source-compatible two-column Householder norm, reflector and dot/reduction order with an independent, fixed execution profile. Only then preregister and seal a **new**, genuinely source-unseen cohort and native Rust binary/predictions before exposing original `robustfit`; retain a separate, scientifically corrected path. The 48 historical source values cannot be reused to claim a new prospective native success.
