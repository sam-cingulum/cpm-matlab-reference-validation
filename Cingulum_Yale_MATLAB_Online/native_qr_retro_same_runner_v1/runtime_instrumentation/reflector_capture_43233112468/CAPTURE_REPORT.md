# Authentic MATLAB R2026b Householder QR reflector buffer capture

**Genuine MathWorks licensed runner:** https://github.com/sam-cingulum/cpm-matlab-reference-validation/actions/runs/43233112468
**Input:** original 48-case synthetic JSON, SHA256 `36f70d7cfd31da808f4c5f61f1127e292597097287a21248782723436f26fa1b`
**Probe:** original `dgeqp3_` Fortran entrypoint inside MathWorks MATLAB executable using LD_PRELOAD forwarding, unmodified numerical inputs/outputs.
**Scope:** selected historical synthetic cases 1, 2, 7, 13, 24 and 48, three repeats, each with public `qr` and original `robustfit`; no independent prospective certification.

## Certified observations for this execution

1. The instrumented `matlab-actions/run-command@v3` step succeeded, and the original MATLAB executable exited normally.
2. Exactly **391 genuine `dgeqp3_` calls** were observed inside the real `/opt/hostedtoolcache/MATLAB/2026.2.999/x64/bin/glnxa64/MATLAB` process. These are actual forwarded calls, not merely symbols bound by the loader.
3. **36/36 selected QR buffers** were captured. Each one matches an original synthetic raw `x` vector exactly in the input column of the design matrix. The 36 selected calls cover all six cases six times each.
4. The captured, original MathWorks `dgeqp3_` output contains the in-place Householder vectors, both original binary64 Householder `tau` coefficients and the triangular factor. Every matrix element, `tau`, and first pivot was **bitwise identical across all six selected executions per case**.
5. All captured three upper-triangular R entries match the genuine MATLAB public QR R exactly for each of the six synthetic cases. The original `robustfit` source R is also independently included in the matched control. In the pivoted rescaled case, original source and public QR R use different column conventions; this is not a MATLAB defect.
6. The complete original `robustfit` R, h, public QR R and pivot fields have **zero mismatches across the clean and instrumented MATLAB controls** (18 vs 18 records, each containing full vectors/matrices). Both control JSON payloads have the same SHA256, `9c11915b08520a0cc25cdce5fcb2d2d5ca95ef90f7d62a1c956868f291ac8b0c`.
7. The snapshot ring had **zero overflow**.

The Fortran `JPVT` input was initially captured as its first raw 8 bytes. The values `0000000000000001` or `0000000000000002`, with the public pivot reference, indicate the MathWorks LAPACK interface uses 64-bit integer pivot slots (ILP64) in this environment. The second private pivot slot is **not captured by this first probe**; the expanded 48-case probe captures and explicitly verifies both pivot slots.

## Independent native MKL comparator (historical disclosed data)

On the owner's separate Linux host, genuine native Intel oneAPI MKL LP64 `LAPACKE_dgeqp3` was given the original raw inputs without any MATLAB output used in its calculations. Against the recorded MATLAB private buffers, results were:

- 6/6 first Householder columns exact, 6/6 first tau exact, 6/6 second tau exact, 6/6 first pivots exact.
- 4/6 complete internal A buffers exact; 15/18 triangular entries exact.
- `baseline_n35_seed649087`: R12 differs by 1 ULP, R22 by 1 ULP; 26 second-column buffer entries differ.
- `outliers_n29_seed648600`: R12 differs by 2 ULP, R22 matches; 13 second-column buffer entries differ.
- Four other cases have complete source-MathWorks vs independent oneAPI MKL buffer identity.

This narrows the remaining difference to the transform of the second QR column in two studied cases. It does **not** prove exactly which floating-point reduction tree or CPU dispatch produced that discrepancy; the private internal per-dot-product intermediate state is not yet observed.

## Scientific acceptance boundary

The original MathWorks binary64 output remains the oracle, and all comparative examinations of the private buffers are marked **RETROSPECTIVE_SOURCE_DISCLOSED_ONLY**. Do not feed source buffer values or corrections into independent compiled Rust predictions. Do not claim exact native Rust raw-input parity, universal Yale coverage, or prospective unseen certification from these snapshots. The 48-case native Rust R/h acceptance gate remains **163/192 exact R and 1,934/2,232 exact h** until a re-executed compiled Rust batch genuinely improves it.
