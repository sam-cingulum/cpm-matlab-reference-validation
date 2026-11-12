# Prospective MATLAB R2026b first-reflector result, frozen independent Rust

- Original MathWorks job: https://github.com/sam-cingulum/cpm-matlab-reference-validation/actions/runs/43241038626
- Original input SHA256: `10ee2f2e6c98e1a09ae10297609306b90b40d5ca48bde6f1589397ad21aa1908`
- Independent compiled pure Rust prediction commit **prior to the MATLAB oracle**: `412ecf99ec75f5a15e71df70e8a0b46166ef5a1a` in `cingulumtechnology/cingulum-cpm`
- Frozen prediction artifact SHA256: `bfffcb4603474da1b827f083f438b722fcbeb0ee4ba4996cca82d440855e7e6c`
- Source-verified tests: 72 completely new synthetic raw predictor cases, six lengths, twelve deterministic scenarios; the original MATLAB source executed only after the independent predictions were frozen and pushed.
- MATLAB normal exit, 216 true internal `dgeqp3_` input/output traces, 72/72 first-stage private reflector state stable across three repeats; instrumented and uninstrumented public QR R and pivot agree exactly across 216 records; zero trace overflows.
- The untouched frozen pure Rust predictions match **72/72 first beta, 72/72 tau1, 72/72 complete first in-place Householder columns, and 72/72 two-element pivot order**, as independently scored in the private Rust repository.
- Strict qualification: this certifies ONLY the first Householder stage for this source-unseen finite binary64 test battery. It does NOT certify the later second-column reflector update, complete QR, leverage, robustfit or Yale CPM end-to-end identity. The source results may now be used for retrospective diagnostics only; the next generalization check requires new unseen inputs.

The archived raw source QR input/output buffers and MATLAB library/CPU fingerprint are original, genuine MathWorks execution artifacts. Source output has not been fed into the independently compiled Rust prediction algorithm.
