# V456 — original MATLAB dense hidden A\B versus explicit QR stage isolation

**Source-DISCLOSED diagnostic experiment. Not new source-unseen acceptance, V12 SEALED.**

## Falsifiable question

V455 showed genuine R2026b dense original `X\Y` changes with appended terminal zero rows while the separately computed public `Q'*Y`, R, and pivots stay bit-identical. Does a public **explicit** QR projection and subsequent solve reproduce the hidden `X\Y` bits? Does MATLAB's decomposition-object QR solver track the hidden result, even though explicit public QR does not?

The source-only `X` and `Y` are the identical 96 V449 cases, SHA **`e2fc94a01754901a2ff9da73f6b4f479857c126e5ce71e962e66fe0b92d4c079`**. **No MATLAB numerical output or independent Rust numerical forecast is read by the original experiment.**

Compare on the same input under the original MATLAB R2026b Update 1 runtime:
1. Hidden default dense `X\Y`.
2. Explicit public economic QR projection `Q'*Y`.
3. Explicit triangular backsolve `R\(Q'*Y)` using the public R.
4. `linsolve(R,Q'*Y,struct('UT',true))`.
5. `decomposition(X,'qr')\Y` (a public decomposition-object solve, not proof of hidden implementation).
6. Backprojection `R*(X\Y)` (an **arithmetic diagnostic**, not direct access to hidden Q'*Y).

Keep raw hexadecimal binary64 bits for every p-dimensional coefficient and projected vector. Do not assume R times hidden beta uniquely identifies hidden intermediate values due to double rounding.

Eight matrices n=48/65, p=9..12, 96 probes (repeated and alternating-sign responses), widths 1,12,16. At n=48, zero padding z=[0,2,3,7]; at n=65 z=[0,1,2,7]. This directly tests the only proven response switch points and two controls. 96 × 4 × 3 = **1,152 panels per original repetition**; original MATLAB reruns every case twice and asserts raw exact repeatability.

Original MATLAB workflow accepts only approved AMD EPYC 7763/9V45, pinned R2026b Update1 mathspec SHA, MKL_CBWR=COMPATIBLE, and one MATLAB thread, and captures all CPU provenance and SHA custody. Failed CPU gate stops **before MATLAB**.

**Interpretation guard:** The two-input `qr(S,B)` that computes C=Q'*B directly is documented for **sparse** S; this investigation concerns **dense** X. It must not be misused as evidence for the dense hidden implementation. The public QR, linsolve and decomposition pathways above are comparisons, not trusted internal MATLAB implementation instrumentation.

The zero-ULP criterion, immutable V371 failure, historical V436 11,481/12,992 source-DISCLOSED benchmark, and full Yale/OHBM V12 SEALED gate are unchanged. Future prospective firstblind original acceptance requires a separate source-unseen frozen Rust forecast, remote SHA verification and strict controls.
