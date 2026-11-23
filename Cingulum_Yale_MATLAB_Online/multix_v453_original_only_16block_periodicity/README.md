# V453 — original MathWorks MATLAB 16-element boundary periodicity

**Source-DISCLOSED numerical investigation, NOT new original-firstblind certification. V12 SEALED.**

V449 genuine MathWorks MATLAB R2026b Update 1 on AMD EPYC 9V45 established that exactly one numerical transition occurs with appended all-zero rows, when the active second-Householder reflector length `m-2` passes from a multiple of 16 to one larger: n48,z3 ⇒ 49; n65,z2 ⇒ 65. It observed no other changes through z16, and public R/pivots remained bit-identical. The matching subset between independently executed approved AMD EPYC 9V45 and 7763 original MathWorks runtimes passed 42,240/42,240 raw coefficient comparisons and 3,568/3,568 raw public R factor comparisons. These are original-to-original comparisons, not compiled Rust parity.

**New falsifiable prediction:** if the hidden response processor truly dispatches by 16-element active reflector blocks, later transitions may occur at `m-2=81,97` (and possibly other first/second-stage effects). This V453 sweep expands the same input X/B to all padding counts z=0..35 and physical response widths 1,12,16, yielding 10,368 hidden solver panels per repetition (two independent original-only repetitions). This includes the predicted next boundary:
- n48: z3, z19, z35 (active lengths 49,65,81).
- n65: z2, z18, z34 (active lengths 65,81,97).

These later transitions are **hypotheses only**, not facts. The runner preserves public R and pivot raw bits at every pad length, and original hidden first two coefficients at every response column. The public original-only input derives from frozen V449 input, not from MATLAB numerical outputs, hidden Rust forecasts or previous scored diagnostics.

Frozen input SHA: `15da245a8ef367890a9edd2c95545ef1709bfe2af7a707166d3c7bfcb4d47803`

Original-only MATLAB runner SHA: `9a69d13d4fb7785fc052b7cd10c5bceb689684a1cf213c9d7e6d28b5c8a8d996`

Generator SHA: `f826ef1ec7898869f42464fa6596192afed799e1a7e867956847816183b6572d`

Original-only workflow checks pinned SHA identities, genuine MathWorks R2026b Update1, `MKL_CBWR=COMPATIBLE`, single MATLAB thread, MathWorks mathspec identity and approved AMD EPYC 7763 or 9V45 CPU, and requires the second run to match every original first run raw bit. Rejected Intel runners must not execute MATLAB.

Do not promote a conditional per-case numerical policy or claim original-source-unseen solver parity. Full V12 remains SEALED until a separately preregistered source-unseen, zero-bit original-firstblind acceptance passes across all applicable Yale/OHBM statistical methods.
