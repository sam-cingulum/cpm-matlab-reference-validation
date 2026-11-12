# Genuine MATLAB R2026b public QR full binary64 capture, 48 historical cohorts

Run: https://github.com/sam-cingulum/cpm-matlab-reference-validation/actions/runs/43219095120

Status: **successful original MathWorks runner**, 12 November 2026. Original `robustfit` unmodified, genuine `qr` public API, 48 previously disclosed synthetic raw x/y cohorts, no patient data. MATLAB R2026b, AMD EPYC 7763 64-Core Processor, `MKL_CBWR=COMPATIBLE`, one numerical thread. GitHub Actions commit `4fe7470689c91b9154d731af7ffdfa16ee508ede`.

Full 924 KB original runner JSON, 48 cases and every 16-hex-digit IEEE-754 double: `full_bit_capture_run_43219095120/full_bit_capture_v1.json`. SHA256 **`282277c69c0d10cc68c8e0ca4ec411e94de066bc8518ab5b26b4d237cff3946f`**. All 48 original `robustfit` R matrices bitwise match same-runner public pivoted QR.

Captured *every available public numerical bit* for each case: original x and y; column-major X; unchanged `robustfit` R/h; pivoted public Q and R; unpivoted public Q and R; pivot; first and second raw columns; first alpha/beta; reconstructed first Householder tau/v; each first-reflector dot product term; every sequential prefix sum and every MATLAB `cumsum` prefix; built-in `dot`, matrix product, `sum`, sequential dot; and complete 48-case second-column vectors produced by six mathematically equivalent candidate operation orders.

**Scope boundary:** MATLAB's public `qr` and `robustfit` APIs do not expose the private actual internal first-reflector vector, exact tau, internal dot reduction tree or transformed second-column working buffer. The archived `v/tau` and transformed columns are explicitly **independently reconstructed**, not claimed to be internal MathWorks temporaries. Capturing those private states requires a separate, explicitly tested runtime instrumentation approach; the available evidence cannot reveal them just by outputting more public fields.

Same-runner candidate comparisons against exact public R12: matrix-product 19/48; built-in dot 19/48; `sum` 16/48; sequential sum 16/48. Matrix-product and built-in dot produce identical dot bits 48/48; scalar sum and sequential accumulation agree with matrix-product on 8/48. The six transformed vector alternatives have nonidentical bit patterns, confirming arithmetic order is a real observable discriminator. None is a complete reconstruction of the proprietary QR kernel.

Reverify locally:

```bash
python3 Cingulum_Yale_MATLAB_Online/native_qr_retro_same_runner_v1/verify_full_bit_capture_v1.py Cingulum_Yale_MATLAB_Online/native_qr_retro_same_runner_v1/full_bit_capture_run_43219095120/full_bit_capture_v1.json
sha256sum Cingulum_Yale_MATLAB_Online/native_qr_retro_same_runner_v1/full_bit_capture_run_43219095120/full_bit_capture_v1.json
```

This is **retrospective source-disclosed forensic evidence**, not a native Rust parity certificate. The next step is targeted instrumentation to capture the actual private first-reflector application on the runner, or an independently validated equivalent kernel with a preregistered prospective original-MATLAB comparison. Keep native Rust 163/192 R and 1,934/2,232 h gate open.
