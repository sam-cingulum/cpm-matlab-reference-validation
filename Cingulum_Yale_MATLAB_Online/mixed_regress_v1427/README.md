# V1427 independent mixed-precision regress holdout

Original MATLAB R2026b Update 1, AMD EPYC 7763 or 9V45, MKL COMPATIBLE,
one thread, exact MathWorks mathspec SHA. The workflow verifies the raw input
and case manifest hashes before executing two original-only repetitions.
No Rust forecasts are included in this repository.

4,794 finite tall or square double designs (2–4 columns, 3–1000 rows), single
responses, fresh dyadic random seeds, duplicate/combination/imbalanced/axis
families, signed axes and adjacent binary32 epsilon boundary ratios. The inputs
are column-major little-endian binary64 X then binary32 y. The original emits
the returned coefficient class, shape, raw words, error/status, last warning
identifier/text and captured console. V12 remains SEALED.
