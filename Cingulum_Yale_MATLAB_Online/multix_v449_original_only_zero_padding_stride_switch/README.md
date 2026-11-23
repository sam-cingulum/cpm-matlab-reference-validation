# V449 genuine MATLAB R2026b original-only zero-padding stride sweep

**Classification:** source-DISCLOSED experiment, **not** new first-original-blind validation. Cingulum CPM universal V12 remains SEALED.

## Hypothesis and newly observed motivation

V441 genuine MATLAB hidden `X\\B` can change raw beta bits when appending mathematically inert terminal zero rows. The public QR `R` factor and pivot order remained bit-identical for all V441 original matrices and z=0,1,7,16. V441 original hidden beta coefficients matched exactly across z0/1 and z7/16; changes were concentrated at z1→7. This suggests physical row stride or response-kernel dispatch rather than a different public QR factor.

V449 determines the **first exact padding increment** that changes hidden beta bits, and whether the threshold is the same across n48/n65, physical response panel width and column index.

Source-only subset of SHA-pinned V441 probes: 96 independent cases (12 fixed RHS patterns per 8 X matrices). Fixed `n=48,65`, `p=9..12`. Padding `z=0..16` (all 17 increments), physical response widths 1,2,11,12,13,16 (six). Two source-original MATLAB repetitions: 9,792 original hidden `X\\B` solves per repetition. Original public `R` and pivot bits are separately archived for every matrix and padding increment.

The source-only input is generated from original-free `V441/input.json`; **nothing** in the generator or MATLAB original runner reads stored genuine original numerical output or independent Rust forecasts.

Frozen V449 input SHA: `e2fc94a01754901a2ff9da73f6b4f479857c126e5ce71e962e66fe0b92d4c079`

Frozen MATLAB original runner SHA: `09eff90c39acfde4c555dcabeb106884f4fd71005f305c5b11964b42a28873ef`

Frozen generator SHA: `b56d3c111d84ec9caf406a8ac330537fee660170c22b92cb391880170831967e`

The workflow enforces original MathWorks R2026b Update 1, approved AMD EPYC 7763/9V45, `MKL_CBWR=COMPATIBLE`, `maxNumCompThreads(1)`, and pinned original MathWorks `libmwmathspec.so`.

Run only after local commit is pushed and independently verified remotely. On unapproved CPU fail closed before MATLAB. Retain and compare all original coefficient raw bits, repeated executions, R/pivot bits, and original CPU provenance.

A successful source-DISCLOSED experiment can diagnose the arithmetic geometry. It **cannot** establish a new zero-bit original-firstblind PASS. V371 original solver FAIL, public Q-only PASS and complete V12 SEALED remain unchanged.
