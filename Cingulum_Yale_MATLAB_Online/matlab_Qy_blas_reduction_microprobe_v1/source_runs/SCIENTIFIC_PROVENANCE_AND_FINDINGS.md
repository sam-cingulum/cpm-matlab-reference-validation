# Genuine original MATLAB R2026b matrix-vector reduction microprobes

## Original source and exact input

Source microprobe original input SHA256: `1b34696f667a7ed057bdb25b799a67bdfd3f506ef2c89c24f450e9b934b6bcd1`, containing **3,610 distinct arbitrary dense two-column matrices Q and paired y vectors**, across **27 exact lengths n=9 through 128**. Every input is directly transported as 16-digit IEEE754 binary64 hex and reconstituted by the *genuine unmodified* MathWorks R2026b `hex2num` API, with exact round-trip assertions. Each original output is the genuine public `Q' * y` matrix-vector multiplication, recomputed twice per original source case with strict bitwise self-repeat verification.

There are **3,070 deliberately constructed cancellation cases** with terms (+2^{54},-2^{54},1) and y identically one. These test the association of *additions independently of multiplication or FMA product rounding*. There are **540 additional general random product cases** for nontrivial binary64 products, cancellation and FMA effects.

Earlier independent genuine R2026b experiments had already established `robustfit` reported st.Qy equals pivot-restored *public* MATLAB `Q' * y` on **480/480 cases across each of four separate original AMD host executions**, thereby isolating original Qy to its public MathWorks numeric matrix-vector multiplication. This microprobe is therefore a direct black-box study of the real underlying public Qy arithmetic, **not** a source-unseen pure-Rust parity certificate.

## Original licensed source runs

| Genuine original MATLAB R2026b run | CPU | Original full 7,220 Qy values |
|---|---|---:|
| [43294167372](https://github.com/sam-cingulum/cpm-matlab-reference-validation/actions/runs/43294167372) | AMD EPYC 9V45 | Source SHA256 `69375185c24d18da1c0b6daa673306f234e13441f4a8fdcb15f4e42caed490a0` |
| [43294171114](https://github.com/sam-cingulum/cpm-matlab-reference-validation/actions/runs/43294171114) | Intel Xeon Platinum **8573C** | Source SHA256 `ff7e0b42873f4c519c5ee430b268c9c06c9089ea1ac929b4e9d5b8c1605cbd66` |

Both original source calculations were fully self-repeating and exited normally. This is Xeon **8573C**, NOT the previously observed 8370C source hardware. Never conflate their numeric profiles. Across the exact same matrix/vector inputs, genuine original MATLAB produced **2,721/7,220 different source binary64 values** between the two CPUs, **2,056/6,140 different cancellation values** and **665/1,080 different general product values**. This is a physically independent cross-CPU original source bitwise nonidentity even though the genuine MathWorks `MATLAB`, `libmwlapack.so` and `mkl.so` original binary SHA256 hashes are identical:

- `MATLAB`: `65c14851fcf1b43a0dc505567c110acd0c8bb68f8294678a1cef8ca25a244460`
- `libmwlapack.so`: `8924853d749f3443c1f4f459c6059bd8d94b5befa317b30f95584e5c8a6c2120`
- `mkl.so`: `afbb1eb0bf3423ab2b049f10047f1d89de097848ded1dd25db060baf81427d04`

## Independently implemented source-disclosed numerical models

Independent, source-free Rust/Python analysis against the already revealed original source bits, *not prospective pre-original forecasts*:

| Original CPU profile | Highest observed tested approximate source-free model | Exact individual original Qy results | Exact cancellation results |
|---|---|---:|---:|
| EPYC 9V45 | Eight-lane vendor-style accumulation | **6,414/7,220**, FAILED full bit parity | **5,930/6,140** |
| Intel 8573C | Eight-lane balanced, fused accumulation | **5,885/7,220**, FAILED full bit parity | **5,412/6,140** |

The best tested models are not universal and do not cover all original bits. Exact cancellation probes sharply isolate different CPU-specific *addition* trees. The AMD model agrees on most cancellation results but differs in predictable subset positions, particularly certain quarter- versus three-quarter-length cancellation pairs, confirming a nontrivial internal grouping/dispatch effect. A separate exhaustive structured *5,760-mode* pure-Rust reduction sweep on genuine 480-case QR-derived Q/y inputs failed to reproduce full original Qy, so this work does **not** imply independent raw-data robustfit identity.

## Immutable original evidence and reproducibility

Every successful source-run folder retains the entire source output as lossless deterministic `original_output.json.gz`, complete actual original CPU/vendor binary fingerprints, original uncompressed-byte `ORIGINAL_BYTES_SHA256SUMS.txt` and archived-byte `ARCHIVED_BYTES_SHA256SUMS.txt`. Both original and archived SHA256 manifests are checked by `tests/matlab_free/analyse_original_matlab_Qy_blas_reduction_microprobes_v1.py` in the separate private Cingulum CPM research repository. No proprietary MATLAB executable or MKL binary has been copied or redistributed.

The first attempted original workflow executions [43293659314](https://github.com/sam-cingulum/cpm-matlab-reference-validation/actions/runs/43293659314) and [43293663689](https://github.com/sam-cingulum/cpm-matlab-reference-validation/actions/runs/43293663689) failed at MATLAB JSON parsing because heterogeneous probe records decode to a cell array, not a MATLAB struct array. This was only a harness-input type issue; no numerical observations were certified from those failed runs. The loader was corrected in public commit `6f29657` and the **exact original input SHA256 stayed unchanged** for both successful source runs.

**Unpassed stages:** exact compiled pure-Rust Qy matrix-vector reduction on every processor profile, original source initial OLS coefficients/scale, iterative original `robustfit` coefficients/robust_s/final s, and end-to-end Yale OHBM original four-mode CPM. These require new, independently frozen compiled-Rust numeric predictions and fresh source-unseen original MATLAB executions, not post hoc expression fitting.
