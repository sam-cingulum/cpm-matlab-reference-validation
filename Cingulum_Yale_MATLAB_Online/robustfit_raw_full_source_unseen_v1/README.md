# Prospective, source-unseen R2026b raw-x/y robustfit experiment v1

Experiment: `cpm-r2026b-independently-implemented-raw-bisquare-original-source-unseen-v1`

**Not a claim of native Rust bitwise parity.** The independent algorithm runs in genuine MATLAB. The original unchanged `robustfit` is the licensed reference.

## Preregistered protocol

1. Generate 48 new original-source-unseen pairs from the separately committed private generator at `242a77f`, before original source call. The 8 families (baseline, outliers, rescaled, high leverage, near flat, negative slope, positive offset and heteroskedastic) each have sample sizes 29, 35, 43, 44, 57 and 71. Input SHA-256 is `36f70d7cfd31da808f4c5f61f1127e292597097287a21248782723436f26fa1b`.
2. Commit inputs, generator provenance, independent clone v2 unchanged, separate Stage A/B MATLAB files, independent fail-closed Python verifier and both workflows *before Stage A*. No original source executed.
3. Run only **Stage A** on genuine R2026b; it must produce clone-only predictions for all 48 cases in IEEE-754 binary64 hex. Download the `forecast.json` artifact, check its authentic workflow run/head SHA, run `python3 scripts/verify_raw_full_source_unseen_v1.py seal-forecast` to immutably pin forecast bytes, code hashes, execution profile and twelve full-field strict gates. Commit and push both `forecast.json` and `forecast_seal.json` **before any original MATLAB call**.
4. Run only **Stage B**, from that newly published revision on the public licensed GitHub Actions runner. It first verifies every source and forecast SHA; then invokes unchanged original `robustfit`, without invoking the independent clone. It writes original binary64 values and invokes the independent, external strict verifier.
5. Accept a prospective exact verdict *only if* all 12 full-field checks are bitwise exact in all 48 original-source-unseen cases, the full leverage and weight vectors and all R elements are exact, and the pinned profiles agree. There is **no tolerance**, fallback parser, missing-case waiver or after-the-fact forecast edit.
6. Preserve failed evidence, even if only one bit mismatches, and use a genuinely new preregistered holdout for subsequent model refinements. Different CPU models/profile settings make original cross-run bitwise certification invalid; this is a separate explicit fail-closed gate.
7. Independently implement and certify raw-input original-compatible pivoted QR in compiled Rust on *new sealed cohorts*. Source-supplied R, beta, h, w or other intermediates are forbidden as an exact end-to-end Rust proof. Yale option-3 full LOO forecast binary64 identity is a later separate milestone.

## Reproducibility details

The frozen fields are `intercept`, `slope`, `R` (all 4 entries, column-major), `h` (all n entries), `w` (all n entries), `mad_s`, `robust_s`, `ols_s`, `s`, `t`, `p`, and `callbacks`. All scalar values use exact 16-character float64 hex, including callback count. The GitHub runner verifies `MKL_CBWR=COMPATIBLE`, `MKL_NUM_THREADS=1`, and `OMP_NUM_THREADS=1` before MATLAB launches. MATLAB is constrained to a single compute thread via `maxNumCompThreads(1)`. MATLAB R2026b was observed clearing `MKL_NUM_THREADS` from `getenv` inside the MATLAB process; this *actual observed value* is captured and must be identical across Stage A and B, rather than inaccurately asserting it stayed `1`. The observed CPU model, MATLAB version, architecture and execution IDs are also recorded and compared. This may not eliminate host-dependent arithmetic differences.

`python3 -m unittest discover -s scripts -p 'test_raw_full_source_unseen_verifier_v1.py' -v` runs adversarial tests including one-ULP corruption, cases dropped/reordered, a missing field, a truncated array, an input-hash mutation and an unpinned runtime profile.

The historical 24-case audit, its previous failures, and the genuine R2026b licensed reference remain untouched.
