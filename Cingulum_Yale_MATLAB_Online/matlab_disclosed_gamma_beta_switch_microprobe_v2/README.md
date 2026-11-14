# Genuine R2026b gamma/beta switch numerical microprobe v2

**Precommitted, SOURCE-DISCLOSED original-MathWorks research only. It is not V12, not a source-unseen test, not a MATLAB-compliant Rust output, and not a Yale scientific-parity certificate.**

This directory contains deterministic raw IEEE binary64 microprobe arguments for original MathWorks `gammaln`, `gamma`, `betaln`, lower and upper `betainc` and `tcdf`. It includes adjacent-ULP boundary points, positive integer and noninteger gamma recurrence, gamma half-integers, incomplete-beta switches, two-sided Student-t df 7/9/13/15/21/23 plus 27/31/35/39 for OHBM-relevant exploration. All inputs are synthetic and public. **There are no source MATLAB numerical answers or user/patient data in the raw input.**

Immutable preoracle input:
- 126 positive gamma arguments, 567 beta a/b/x triples, 170 Student-t df/t pairs.
- `input.json` SHA256: `bae7d427f4866d92f4435a8803730b9114886199edb0c03df594bbd3803159dc`.
- Exact published `input.sha256` and reproducible `generate_disclosed_inputs_v2.py`.

Original-only stage:
1. Validate the published `input.sha256` and CPU model **before** invoking MATLAB.
2. Require unchanged genuine R2026b and Statistics Toolbox, `MKL_CBWR=COMPATIBLE`, one thread and eligible original AMD EPYC.
3. Execute unmodified MathWorks functions twice for every input, recording exact `num2hex` and recurrence/branch transformations, original MATLAB version, CPU and binary fingerprints.
4. Verify full original fields, every row, two executions, input SHA and one-bit negative control with `verify_original_gamma_beta_switch_microprobe_v2.py`.
5. Permanently archive original numeric output bytes and run/CPU manifests *after actual eligible workflow completion*. Actions artifacts alone are not permanent.
6. Independently compile original-blind Rust numerical candidates using only these raw public inputs, grade failures via exact hex bits and ULP taxonomy. Never supply original numeric intermediate values to a purported independent forecast.

Dispatch workflow: `.github/workflows/matlab-disclosed-gamma-beta-switch-microprobe-v2.yml`. An unsupported runner CPU intentionally fails with code 86 *before* executing original MATLAB, and is not a numerical result. Repeat eligible original source on a second certified AMD host when available.

V12 remains strictly locked until the independent native V11 full source-disclosed Student-t 1,920/1,920 exact probability elements, paired coefficients and all full original stats pass. Existing unsuccessful candidates and V11 19-field internal source-unseen evidence are not altered by this experiment.
