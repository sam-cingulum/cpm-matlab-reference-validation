# V1365 — Gram and inner-product order at the lasso scale (source-disclosed diagnostic)

Not evidence for any certificate. V1362 (Yale `ridgeCPM` / `ridgeCPM_PCA` firstblind, FAIL
63/88) left six workspace-scale `lasso` fits open: covariance solver, alpha 1e-9 or 1e-6,
180 to 400 active predictors and 800 to 900 training rows. This probe reads, on genuine
MATLAB R2026b Update 1 (approved AMD EPYC 7763 / 9V45 only, `MKL_CBWR=COMPATIBLE`):

- **A** `Z'*Z` and `Z'*W` (`W` an unshared copy) for twister data, 256..2,000 rows and
  65..400 columns (`gram.bin`).
- **B** FPRev anchor rows of the summation trees of `Z'*Z` at 900x360, 800x180 and
  2,000x252 (`trees.bin`; marks ±2^40 per factor, ±2^80 per product).
- **C** inner products `a'*b`, `b'*a`, `sum(a.*b)`, `dot(a,b)`, `M(:,j)'*b`, `M(j,:)*b`,
  `M*b`, `b'*M` for n = 1..2,000 (`dots.bin`) and FPRev rows of `a'*b` (`dottrees.bin`).
- **D** genuine `lasso` on twister data at the V1362 scale shapes (`lasso.bin`).

Synthetic seeded inputs only. Reads no Rust forecast and no earlier MATLAB output. V12 SEALED.
