# Prospective SOURCE-DISCLOSED R2026b V10 beta mean-tail challenge

**Explicitly new source-disclosed numerical challenge; NOT V12.** Designed after V9's discovered mean-tail complement invariant, but all new raw inputs and the unmodified original MATLAB runner are publicly frozen and pushed **before** executing original MATLAB. All independent Rust numeric forecasts for this newly disclosed domain must be separately SHA-committed **before** source execution. The inputs are disclosed, not secret source-unseen certification.

Novel arguments, without MATLAB numeric bits or source failure matching:
- 60 positive gamma inputs, including fractional and high half-integer arguments with immediate floating-point neighbours
- 2,812 distinct beta triples crossing mean `a/(a+b)` and Numerical Recipes switch `(a+1)/(a+b+2)` ±1 ULP for 149 paired parameter shapes, including independently seeded log-space fractional shapes, low tails near 2^-200, and upper tails near 1-2^-50; this is deliberately different from V7's 887 points
- 208 Student-t inputs with new even df values, near t²=df switching and tail edge cases

Exact raw V10 input SHA256: `ed1b3af2b864241caa9719a3dc8ceb2df670c0a9bf426cf741d5959d60adedc5`.

Original R2026b runner is a fresh V10 instance, executes unmodified vendor `gammaln`, `gamma`, `betaln`, `betainc` with both `lower` and `upper`, `tcdf`, and elementary stages **twice**. Hard gates: MathWorks `2026b`, `MKL_CBWR=COMPATIBLE`, one thread, AMD EPYC 7763/9V45/9V74 hardware, CPU/vendor binary fingerprints, complete original per-field SHA and two bit-exact repeated executions. Strict validators include original one-bit corruption rejection. Never use Octave, substitutions, MATLAB numeric intermediates injected into independently compiled Rust, user or clinical data, or looser epsilon validation.

**Falsifiable independently prospective hypotheses:**
1. Original `betainc` upper == binary64 `1-lower` whenever x < a/(a+b)
2. Original lower == binary64 `1-upper` whenever x >= a/(a+b)
3. The two opposite direction operations are *not* always bit equal, particularly near extreme tails
4. Original Student-t matches its original explicitly evaluated piecewise beta tail
5. Original outputs are byte-identical on two distinct preapproved AMD original execution hosts

Source original results must be permanently archived by verified exact SHA and CPU provenance before scoring newly precommitted native Rust. Record any hypothesis falsification; never retrofit input, thresholds, original data or prior successful reports. This challenge is separate from the ungenerated sealed V12 robustfit / Yale end-to-end pipeline gate.
