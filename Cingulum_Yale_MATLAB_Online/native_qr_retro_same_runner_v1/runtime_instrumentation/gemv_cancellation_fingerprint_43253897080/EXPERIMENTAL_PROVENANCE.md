# Original MathWorks vendor BLAS exhaustive three-term reduction experiment

Genuine MATLAB R2026b licensed execution: [run 43253897080](https://github.com/sam-cingulum/cpm-matlab-reference-validation/actions/runs/43253897080). Unmodified MATLAB `qr` and `robustfit` numerical source and original MathWorks bundled `mkl.so` library.

- **733,194/733,194** complete ordered three-term cancellation DGEMV cases covering every distinct assignment of (+2^53, -2^53, +1) to 3 independent positions in dimensions 29, 35, 43, 44, 57 and 71. All other terms are exactly zero; matrix multiplier consists entirely of exact ones. No other floating-point data enters these vendor DGEMV calculations.
- Complete original vendor outcome bits retained in compact, unambiguous `QR3BIN01` little-endian format: eight magic bytes, uint32 record count, then 5-byte records `(n,plus_index,minus_index,small_index,outcome[0 or 1])`. Records follow dimension, small index, plus index and minus index nested ascending loops, skipping collisions.
- Each original DGEMV microprobe executed twice with identical results. **Zero numerical drift, zero overflow, zero unexpected output.** Original source QR numerical results unaffected by the probe: 144/144 uninstrumented/traced runs exact across original 48 cases × three repetitions, including complete `R`, original `robustfit` `R`, all leverage `h` entries and pivot orders. Normal process exit.
- Original vendor DGEMV scratch reconstruction of R12 and full-source DGEQP3 agree 48/48. Raw original DGEQP3 record and vendor original dot details archived as `qr_vendor_exhaustive_second.log`.
- The CPU was **AMD EPYC 7763**. Keep independent host and original vendor library fingerprints with the capture for cross-CPU provenance.

The original vendor outcomes are disclosed forensic evidence, **not a prospective source-unseen certification** for new independently constructed Rust kernels. Never substitute MathWorks code or binary libraries into native Rust parity claims. A novel Rust reduction algorithm derived from this evidence must first be frozen and then tested on fresh original-MATLAB-prospective datasets.
