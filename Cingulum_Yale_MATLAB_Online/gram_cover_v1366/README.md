# V1366: Gram coverage diagnostic (source-disclosed, not a certificate)

V1365 (`gram_dot_v1365/`) recorded MATLAB R2026b's `Z'*Z` at seven widths from 65 to 400 and
genuine `lasso` fits at the V1362 workspace scale. A summation model of MKL's syrk (64-row
panels, 12-column tiles, an edge lane kernel and K blocks) reproduced every recorded word.
That model was fitted on those widths, so this run records the shapes it has not seen:

- A1: every width from 2 to 140, at 300 and 800 rows;
- A2: widths 66, 77 and 131 at 32 row counts from 257 to 3,000 (the K-block rule);
- A3: widths 401 to 1,199 at 900, 1,200 and 2,000 rows (the covariance lasso runs to n-1 predictors);
- B: genuine `lasso` at 14 new width and row-count pairs.

Plain MATLAB, no MEX, `MKL_CBWR=COMPATIBLE`, one thread, approved AMD EPYC 7763 or 9V45 only
(other CPUs exit 86 before MATLAB starts). Synthetic twister inputs regenerated from the seeds;
the file layouts are in `run_v1366.m`. Reads no Rust output. V12 stays SEALED.
