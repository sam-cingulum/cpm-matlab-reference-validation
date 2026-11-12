# Genuine MATLAB R2026b uninstrumented QR control: confirmed repeatability and instrumented comparison

- Genuine uninstrumented MATLAB Actions runner: https://github.com/sam-cingulum/cpm-matlab-reference-validation/actions/runs/43227210582
- The MATLAB execution step succeeded; the workflow verifier **initially failed** because it incorrectly assumed that source `robustfit` R must equal public QR R even when the public QR pivot order is `[2,1]`. The rescaled synthetic case is correctly pivoted and cannot satisfy that assumption. This was a verifier defect, not a MathWorks numerical failure. The corrected verifier passes against the complete archived 18-record output.
- Six original synthetic cases, three sequential runs each. **All public QR R, original robustfit R, original robustfit h and pivots are bit-for-bit identical within each case across the three repetitions.** SHA256 of original archived control JSON: `9c11915b08520a0cc25cdce5fcb2d2d5ca95ef90f7d62a1c956868f291ac8b0c`.
- Comparison against instrumented genuine MATLAB `LD_AUDIT` run 43220857431: **6/6** cases have both R12 and R22 identical to this uninstrumented control.
- Comparison against instrumented `la_x86_64_gnu_pltenter` audit run 43222091948: **1/6** cases has both R12 and R22 identical; remaining cases have 1–several ULP differences. The second tracer captured **zero actual QR function calls**, despite library bindings. This establishes the second instrumentation configuration is **not numerically noninterfering** relative to the uninstrumented control. It does not prove the precise mechanism of interference.
- The first loader audit still returned process exit 255, despite numerically identical R12/R22. Its numerical invariance is only established for these selected entries, **not full R/h**.

## Implications

Use the uninstrumented baseline as the bitwise oracle. Do not use the PLT-entry tracer for numerical parity or private buffer evidence. For future instrumentation, require full original R and h exact against a same-runner uninstrumented control, and normal process completion, before accepting a trace. Genuine private reflector state and reduction tree remain unobserved. No native Rust parity claim changed.
