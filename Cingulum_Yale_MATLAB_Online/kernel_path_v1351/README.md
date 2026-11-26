# V1351 — large-row dgemm summation-order probe (source-disclosed diagnostic)

Not evidence for any certificate. V1350 showed that genuine MATLAB R2026b `X\B` departs from
the Rust model only when blocked `dormqr` (9 or more columns) meets 13 or more right-hand
sides and 400 or more rows. This probe locates the cause in MathWorks' own BLAS through a
plain MEX gateway (`kp1351.c`, linked with `-lmwblas -lmwlapack`):

- **A** `X\B` vs `dgeqp3` -> `dormqr('L','T')` -> `dtrtrs`, and `dormqr` vs blocked
  `dlarft` + `dlarfb` (nb 8) with `dlarfb` either MKL's or rebuilt over the public `dgemm`
  (`chain.csv`).
- **B, C, D** FPRev summation trees (`trees.bin`) of `dgemm('T','N')` W += C2'·V2 (inner
  length L up to 2,000; full trees up to L = 1,000, anchor rows beyond) and `dgemm('N','T')`
  C2 -= V2·W' (inner length k). Marks are ±2^80 so partial sums of up to 2,000 ones stay exact.
- **E** both products on seeded random data with dlarfb-like strides and alignment
  (`gemm_rand.bin`), to decide where FMA is used.
- **F, G** genuine `X\B` (400..2,000 rows, 9..40 right-hand sides) and `robustfit`
  (1,500 and 2,000 rows) in the V1350 containers (`mldivide.bin`, `robustfit.bin`).

Synthetic seeded inputs only; reads no Rust forecast and no earlier MATLAB output. V12 SEALED.
