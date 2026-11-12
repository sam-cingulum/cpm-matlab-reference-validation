# MATLAB R2026b complete QR 480 adversarial source-unseen certification provenance

The original 480 raw-input cohort is scientifically new, generated before original MathWorks source execution: **40 lengths n=9..128 × 12 independent challenging predictor distributions** (near-flat, shifted, extreme small/large scales, heavy tail, alternating cancellation, impulsive, clustered, etc.). All x and y are transported as **exact binary64 hexadecimal**, not decimal JSON floats. Raw original input `input.json` SHA256 `2f73eb85ae189b39959aeda941d00eb858782d28514099e4a89dfddf2ac959f5`.

The original source-blind **compiled native pure-Rust predictions for every scalar R11/R12/R22, tau1/tau2, pivot, and every original in-place first and second Householder column element** were frozen, tested and pushed at private Cingulum CPM commit **`ebeff71e7e1270c03473ca0a04a95eb152dda0f1`** before original MATLAB execution began. Frozen original-independent JSON output SHA256 `eca6b5b7c9dfc8fd4aba94686064ce2d3137742ab79aa16839fd5c067a271ac3`.

The original math source is genuine **licensed, unmodified MATLAB R2026b**, with original `qr` and `robustfit`, original MathWorks BLAS/LAPACK. All runs perform 3 original source repetitions uninstrumented, and then exactly 3 more under a read-only QR working-buffer capture. On every run the original full R, original `robustfit` R/h/beta, original double-valued stats and pivots are bitwise identical both across repetitions and across uninstrumented/instrumented source. 480/480 original robustfit runs succeeded without errors. All **2,880** original private QR buffer events per host repeat identically, no mismatched raw input, overflow or MATLAB failure. The original CPU model, vendor library binary hashes and all complete source output bits are archived here.

| Original licensed MathWorks run | CPU | Frozen native Rust complete in-place A / both tau / complete R / pivot |
|---|---|---:|
| [43271660198](https://github.com/sam-cingulum/cpm-matlab-reference-validation/actions/runs/43271660198) | Intel Xeon Platinum 8370C | **20/480**, failed (formal negative control) |
| [43271666489](https://github.com/sam-cingulum/cpm-matlab-reference-validation/actions/runs/43271666489) | AMD EPYC 9V74 | **480/480**, passed |
| [43271671956](https://github.com/sam-cingulum/cpm-matlab-reference-validation/actions/runs/43271671956) | AMD EPYC 9V74 | **480/480**, passed |

AMD source-unseen exact 18,432/18,432 first-column binary64 source values AND 18,432/18,432 second-column values PER AMD host. Intel differed on 460/480 full fields, even though genuine original source was stable and instrumented controls passed. This shows source profile-specific semantics and does NOT certify universal MATLAB execution or full Q/leverage/robustfit.

## Lossless archived source files

- `qr_adversarial_fullqr_480_clean.json.gz`: entire unchanged original numerical `qr`/`robustfit` source 1,440 records.
- `qr_adversarial_fullqr_480_captured.json.gz`: entire captured original QR and robustfit, 1,440 records.
- `qr_adversarial_fullqr_480_private_buffers.log.gz`: 2,880 complete original private QR working vectors, tau, original input, pivots.
- `qr_adversarial_fullqr_480_calls.log.gz`: call capture provenance.
- `qr_adversarial_fullqr_480_source_gate.json`: strict original-source bitwise and repeat checks.
- `qr_adversarial_fullqr_480_cpu_and_vendor_fingerprint.txt`: physical CPU and exact original MATLAB/vendor library SHA256 hashes.
- `ORIGINAL_BYTES_SHA256SUMS.txt`: checksums for all *decompressed original byte streams* exactly as emitted by genuine MATLAB on the runner.
- `ARCHIVED_BYTES_SHA256SUMS.txt`: checksums for stored losslessly compressed evidence files.

To audit, `cd <source_run_dir> && sha256sum -c ARCHIVED_BYTES_SHA256SUMS.txt`; to reproduce original source bytes, `gzip -dc qr_adversarial_fullqr_480_private_buffers.log.gz > /tmp/qr_adversarial_fullqr_480_private_buffers.log`, likewise for each `.json.gz` file, and verify SHA from `ORIGINAL_BYTES_SHA256SUMS.txt`. `gzip -n` removes any non-deterministic timestamp in the compressed transport. The exact-original-source evidence is therefore fully preserved after GitHub Actions artifact expiration.

## Independent original MATLAB on Ubuntu 22.04: two additional AMD processor models

We explicitly re-ran the original MATLAB source against the **same 480 source-unseen frozen pure-Rust outputs** (private original commit `ebeff71e7e1270c03473ca0a04a95eb152dda0f1`) using an alternate `ubuntu-22.04` GitHub runner to broaden hardware and OS coverage. Both original MathWorks executions independently passed the full 480-case exact gate. Original `qr` R, in-place 2×n A, both tau coefficients, pivots, original `robustfit` output and all source numeric statistics were unaffected by read-only capture, and all 2,880 source-private events repeated bitwise identically on both hosts.

| Original licensed MathWorks source run | CPU | Frozen pure Rust complete A + full R + tau + pivot |
|---|---|---:|
| [43272898862](https://github.com/sam-cingulum/cpm-matlab-reference-validation/actions/runs/43272898862) | AMD EPYC 7763 | **480/480** |
| [43272904738](https://github.com/sam-cingulum/cpm-matlab-reference-validation/actions/runs/43272904738) | AMD EPYC 9V45 | **480/480** |

**Updated stress-suite AMD outcome: 1,920/1,920 complete-QR full-field results across 4 original AMD hosts (EPYC 9V74 twice, 7763, 9V45); 73,728/73,728 per-column individual original binary64 A entries exactly reproduced (4 × 18,432).** An additional 480-case Intel Xeon 8370C negative control is preserved as a formal failure (20/480 exact). Including the previous independently frozen 240-case battery, AMD full-QR prospective evidence totals **2,400/2,400** across six original MATLAB AMD executions. This proves only the tested numeric operation/profile and sample families, not universal MATLAB QR or any full-Yale CPM identity.

The new Ubuntu 22.04 source files are independently archived with lossless `gzip -n`, original-byte and archived-byte SHA256 manifests and source CPU / vendor library hashes, exactly as the earlier original Ubuntu 24.04 runs.
