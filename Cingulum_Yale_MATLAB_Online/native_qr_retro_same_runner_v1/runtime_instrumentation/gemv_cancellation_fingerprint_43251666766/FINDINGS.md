# Original MathWorks DGEMV addition-tree microbenchmark, genuine R2026b

**Unmodified original MathWorks run:** [43251666766](https://github.com/sam-cingulum/cpm-matlab-reference-validation/actions/runs/43251666766).

This experiment first executed genuine `qr` and `robustfit` on 48 historical synthetic raw-x cases for three repetitions **without** instrumentation and separately with an `LD_PRELOAD` wrapper that calls the original MathWorks vendor `DGEMV` on scratch-only buffers **after** each original QR has returned. Normal process exit. Original `qr` R, source `robustfit` R/h and pivots matched the original uninstrumented control in every one of 144 output records, with every individual binary64 bit equal. The canonical reference SHA256 is `d059026575c68ea7b8e879157226e316f4eca65c8590e5ea09176ace44854a97`.

## Original vendor BLAS result isolated

The experimental original `DLARF` update and standalone original `DGEMV` plus Householder top-row update reproduced the unchanged original `DGEQP3` R12 in **48/48 historical cases**, including all 288 QR calls; original `DDOT` is not a numeric substitute. The actual environment's binary was MathWorks `mkl.so` and its host was an AMD EPYC 9V45 96-core processor.

## New BLAS arithmetic reduction fingerprint

We measured **19,974** separate, deterministic `DGEMV('Transpose', m, 1, A, m, x)` outcomes at six lengths (29,35,43,44,57,71). For each probe, the matrix column A consisted entirely of binary64 ones and x contained exactly three nonzeros at distinct positions: +2^53, -2^53 and +1. All other elements were exactly zero. We systematically varied the positions of the two large cancelling terms and placed the small +1 at row zero, the middle row, and the final row. Because a binary64 sum of these exact elements is sensitive to addition association, the output may be zero or one depending on the original BLAS reduction tree; multiplication by one introduces no rounding noise.

Each vendor DGEMV probe was independently executed twice and produced identical bits. All 19,974 outputs were finite and exactly zero or one. 19,974/19,974 expected probes captured with zero overflow or repeat mismatches. The full original vendor binary64 microprobe responses, exact code and CPU/MATLAB library fingerprints are archived here with SHA256 manifest.

**Strict scientific qualification:** The 19,974 responses are vendor-source **disclosed after experimental execution**. They can be used to discriminate candidate reduction trees retrospectively but not to certify a newly selected pure-Rust algorithm. General second-column parity requires an independently compiled Rust algorithm frozen prior to genuinely unseen source execution. No proprietary MathWorks binary was altered, copied or redistributed.
