# Original genuine MATLAB R2026b source-unseen 320-case QR / robustfit oracle

**Original source execution:** [GitHub run 43257619147](https://github.com/sam-cingulum/cpm-matlab-reference-validation/actions/runs/43257619147). Original `qr` and `robustfit` executed in genuine licensed MathWorks R2026b, linked to MathWorks `mkl.so`. No MATLAB numerical binary or code modified. All input values reconstructed from exact binary64 hexadecimal transport using MATLAB `hex2num`; original hex bits asserted for every x and y.

**Critical independent pre-oracle freeze:** The compiled pure-Rust forecast for every case was generated, SHA256-pinned and pushed at Cingulum CPM private GitHub commit `4c35c9824e15283aff57993fecd12415d847d5a9`, **before any successful original MATLAB execution**. Input SHA256 `b03922f51ae9c5edc2bec7f68df01979d8f915ec0d8467179bbd580fa9871efe`; sealed forecast SHA256 `9d832bfd4563bc0e55b68c9d00378b7591500c3ad779e5eca5d7d00c9a77257c`. This public original-source archive never used the private Rust forecast as a numerical input.

320 fresh raw-input cases cover **40 vector lengths from 9 to 128**, including original and never-before-tested AVX/dispatch boundaries, with eight input families each. Each was repeated three times in the uninstrumented original MATLAB execution and in a separate original run under read-only numerical buffer instrumentation. All 960 original QR R/pivots and entire original `robustfit` numeric `stats` fields, output beta, R/h match the instrumented source **bit for bit**. No original robustfit errors, 320/320 original source cases stable across all repetitions. 1920 true original private `dgeqp3_` working buffer samples, first and second Householder coeffs, and raw input bytes captured, zero overflow, source R/pivots independently cross-checked.

- `qr_vendor_tree8_320_clean.json`: complete unmodified original 960-record numeric source oracle.
- `qr_vendor_tree8_320_captured.json`: independent instrumented exact 960-record original source, identical SHA256.
- `qr_vendor_tree8_320_private_buffers.log`: original first and second Householder raw A input/output working columns, tau and pivots, all 1920 executions.
- `qr_vendor_tree8_320_source_gate.json`: strict numerical noninterference, raw-input and private-buffer validation.
- `qr_vendor_tree8_320_cpu_and_vendor_fingerprint.txt`: complete CPU and exact original MATLAB/mkl library identities.

The first initial run 43257078161 failed due a test script input-path error **before any MATLAB numerical algorithm or original oracle output was computed**; the corrected script in commit `ad4eec4` was executed in run 43257619147. No independently frozen predictions were revised. Source outputs can now be revealed to the independent Rust scorer. The gate does **not** itself claim any bitwise parity for native Rust; score all frozen fields separately and preserve failures.
