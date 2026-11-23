# V441 — genuine MATLAB R2026b hidden-panel cancellation microbattery

**Scientific classification:** source-DISCLOSED reduction identification, **not** new source-original first-blind certification. Comprehensive V12 remains **SEALED**.

The V440 independently SHA-custodied audit found that, for the **n=65 second coefficient**, genuine MATLAB original results remain raw-bit stable within RHS widths 1–11 and within widths 12–16; the same input often changes at the 11→12 boundary. The hidden A\\B solver's physical response-panel dispatch must therefore be distinguished from explicit public Q'*B.

This folder contains **only** pinned V377 original-only X matrices and newly generated independent dyadic/impulse/cancellation RHS inputs. Nothing here can read independent Rust numerical predictions, hidden solver forecasts or stored MATLAB answers. The generator uses deterministic inputs only.

- Eight n48/n65 × p9–12 matrices, 320 fixed response probes.
- Physical RHS widths **1, 2, 11, 12, 13, 16**; terminal padding **0, 1, 7, 16**.
- Single impulses at 24/25, 31/32/33, row tails; exact oppositely signed pairs; one-ULP cancellation; dyadic arrays; signed zero; repeated versus alternating-sign columns.
- MATLAB original solver has **7,680** panel solves per repetition and runs **twice** on the same approved AMD EPYC CPU.
- Original raw IEEE754 coefficient bits, original R/pivots, CPU provenance, MathWorks mathspec SHA and original input SHA are retained.
- Different approved AMD EPYC hosts must be separately run for the cross-AMD gate.

Frozen input SHA256: `fd6422211331eb71c6609e251ffb50a69b9c3a2338c077fd388f972e3b492457`.

Frozen original-only MATLAB runner SHA256: `4cdef19919a6fc6d80762607214d81d5c6c66188e37382f0b0117923b6cbfe06`.

Regenerate via `python3 -B generate_v441_source_only.py`, verify `sha256sum -c input.sha256` and verify both pinned SHA values in the workflow. Only run after public source commit is pushed and its remote SHA verified. The manual `matlab-v441-disclosed-hidden-panel-cancellation.yml` workflow fails closed on unapproved CPU, MATLAB version/toolbox mismatch, or source SHA mismatch.

Do not use these already source-DISCLOSED inputs to claim a new prospective whole-solver first-blind PASS. The next step is to retrieve genuine original-only results, cross-check both independent repetitions and AMD hosts, and derive a single physical-kernel arithmetic implementation without source-conditioned per-case selection. V371's FAIL and V410's PUBLIC-Q-only PASS are unchanged; V12 stays SEALED.
