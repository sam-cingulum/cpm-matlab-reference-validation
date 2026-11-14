# Genuine original R2026b, SOURCE-DISCLOSED gamma/beta branch V2: permanent results

Date: 14 November 2026, Melbourne. **Original source-disclosed numerical evidence only. NOT V12 and NOT independent Rust parity.**

## Preexecution source, host and input gates

Original MATLAB runner/input/workflow **already public before any original execution** at commit `2e329bd5038ace9d99d5668c3811fad89941aadd`, 126 gamma arguments, 567 incomplete-beta triples, 170 Student-t pairs. Original public input SHA256 `bae7d427f4866d92f4435a8803730b9114886199edb0c03df594bbd3803159dc`.

Two actual genuine unchanged MathWorks MATLAB R2026b Update 1 runs completed successfully:
- <https://github.com/sam-cingulum/cpm-matlab-reference-validation/actions/runs/43541967648>: **AMD EPYC 9V45**, native original step, repeat verification and original manifest **PASS**.
- <https://github.com/sam-cingulum/cpm-matlab-reference-validation/actions/runs/43541973927>: **AMD EPYC 7763**, native original step, repeat verification and original manifest **PASS**.

Both used one MATLAB/BLAS thread, `MKL_CBWR=COMPATIBLE`, original builtin `gammaln`, `gamma`, `betaln`, lower/upper `betainc` and `tcdf`, and emitted two identical full-field repetitions. All original data bytes are **identical across the two different AMD CPUs**, SHA256 `e0f056aa297f8c9d26232e879b69f13dbf8dcd6a2e4d6f68e91ea8766a1aba33` (763,517 uncompressed bytes).

Two unsupported Intel CPU runs `43541830604`, `43541970655` correctly **failed the original CPU gate with code 86 BEFORE MATLAB**. They were not original numerical results and must not be counted as failed numerical comparisons.

## Immutable source artifacts

`SOURCE_ORIGINAL_SHA256_PROVENANCE_MANIFEST.json` records CPU SHA, original output SHA, compressed source artifact SHA, run IDs, original runner Git HEAD, input SHA, and the rejected host IDs.

Preserved deterministic gzip under:
- `source_runs/43541967648/original_gamma_beta_switch_microprobe_v2.json.gz`
- `source_runs/43541967648/cpu_and_original_vendor.txt.gz`
- `source_runs/43541967648/original_sha256_manifest.txt.gz`
- `source_runs/43541973927/original_gamma_beta_switch_microprobe_v2.json.gz`
- `source_runs/43541973927/cpu_and_original_vendor.txt.gz`
- `source_runs/43541973927/original_sha256_manifest.txt.gz`

The original source verifier validated complete expected shape/order, exact source input hex, 2/2 repeated bitwise originals for all original outputs, and rejected a one-bit tamper of the first original gamma value. This is **original source repeatability evidence**, not proof of original correctness against a high-precision mathematical oracle or independent Rust parity.

The separate independent compiled Rust original-output-blind prediction has been committed to private Cingulum CPM under Git commit `867e3d7c1540e2005d60eb6716134f72ade45a7d`, raw SHA256 `d95b3fd672fd5db654bce808ae4540214c3ec616537246025a2b009b390f2596`. It ingests only the pre-published raw numerical inputs, never any original MATLAB answer or numerical intermediate.

All original SHA and CPU manifests must be validated independently before comparing that forecast to any source output. Source-disclosed mismatches cannot be relabelled source-unseen V12 successes.
