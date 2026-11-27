# V1424 single-precision Cauchy tail diagnostic

This source-disclosed diagnostic measures original MATLAB R2026b Update 1 on
AMD EPYC 7763 and 9V45, with one thread and MKL CBWR COMPATIBLE. The workflow
verifies the MathWorks mathspec binary identity and compares two repetitions
word for word. It exports each field's MATLAB class and shape with its raw
little-endian IEEE words.

`t_words.csv` contains 29,723 distinct absolute binary32 t statistics derived
from the synthetic V1422 and V1423 correlation diagnostics. For each finite
`0 < abs(r) < 1` with one degree of freedom, the extraction forms
`b = single(1 - single(r*r))`. It evaluates `r*sqrt(1/b)` for `corr` and
`r/sqrt(b)` for `partialcorr`, rounding each operation to single. The scalar
subset includes the 92 distinct arguments where the baseline BSD polynomial
missed the recorded p-value, plus regularly spaced samples. The harness adds
signed zeros, infinities, NaNs and subnormals to that subset. The signed sample
and independent seeded atan sweep exercise both signs, reduction boundaries,
and the full binary32 exponent range.
