# Frozen source-unseen original robustfit leverage h and complete two-column Q in native Rust

**Scientific acceptance:** independently compiled pure Rust reproduces original licensed MathWorks R2026b raw-x two-column full Q, original coefficient-ordered R, both tau, all in-place A and specifically original `robustfit` leverage h, **every field exactly 480/480** in each original-source execution. The entire leverage h vector is exact **18,432/18,432** original IEEE754 binary64 values per host.

The source-unseen 480 raw binary64 subjects were frozen at SHA256 `3e7ceb16a2a554a15c4d5f07b36f9d900c92d63e9162b9ad6a9233e7e708e7b1`; the entire independently compiled Rust full-Q/full-R/h field predictions at SHA256 `fbdee51a5512ecf0201b014940f30dc57639edf74fe2b8b5f418b26e5500c92d`, already pushed in private commit `0516d29cde88cc419f76590e7a26f54d45825a0d` BEFORE the first original MATLAB source run.

Original R2026b licensed genuine runs [43277638801](https://github.com/sam-cingulum/cpm-matlab-reference-validation/actions/runs/43277638801) and [43277645354](https://github.com/sam-cingulum/cpm-matlab-reference-validation/actions/runs/43277645354) on AMD EPYC 7763 both completed successfully. Every full Q entry 36,864/36,864 and original leverage h entry 18,432/18,432 matched frozen independent Rust EXACT per host. Original `qr` and original `robustfit` full fields including h, beta and all numeric stats are bitwise unchanged under instrumentation; 2,880 private QR buffer observations per host identical on six duplicates per case, zero overflow/robustfit error, normal process exits.

**Source-faithful h rule:** original coefficient ordered `R` from exact pivoted QR, `Z=X/R`, original `h=sum(Z.^2,2)` with separately rounded binary64 scalar right-division operations. For pivot [1,2], `z1=1/r11; z2=(x-z1*r12)/r22`; for pivot [2,1] after unpermuting R, `z2=x/r11; z1=(1-z2*r12)/r22`; then `h=z1*z1+z2*z2`. These operations are source-free Rust computed solely from raw x. Merely `sum(Q.^2,2)` is NOT original source bitwise h.

All exact original results, full Q, h, private QR, CPU/vendor SHA fingerprints and byte-level checksum manifests are losslessly archived. This certifies **QR, Q and original leverage h only** for the tested AMD execution profile; original robustfit scale/robust_s/t-statistics and complete Yale CPM end-to-end exact parity remain open. Intel's distinct MathWorks numeric profile is still an explicit nonparity control.

## Independent alternate Ubuntu 22.04 original MATLAB certification: source-unseen and bitwise exact

The **same immutable pure-Rust source-blind prediction** (`0516d29cde88cc419f76590e7a26f54d45825a0d`, SHA256 `fbdee51a5512ecf0201b014940f30dc57639edf74fe2b8b5f418b26e5500c92d`) was independently checked with the original unchanged MathWorks MATLAB R2026b and `robustfit` on Ubuntu 22.04, in two additional original source executions:

| Original source run | Physical original CPU | Complete R/Q/Householder/tau and original robustfit h exact | Individual original h bits exact |
|---|---|---:|---:|
| [43278621416](https://github.com/sam-cingulum/cpm-matlab-reference-validation/actions/runs/43278621416) | AMD EPYC 7763 | **480/480** | **18,432/18,432** |
| [43278627539](https://github.com/sam-cingulum/cpm-matlab-reference-validation/actions/runs/43278627539) | AMD EPYC 9V74 | **480/480** | **18,432/18,432** |

Both original source runs had 100% identical original 1,440-record source full-Q/QR/robustfit numerical values between original and traced runs, all 2,880 private original Householder buffer events repeated exactly, no overflow, no robustfit exceptions and normal completion. The original source and trace are archived losslessly with SHA256 manifests. This brings the new source-unseen `robustfit` leverage gate to **1,920/1,920 full-field exact cases and 73,728/73,728 individually exact source original leverage values** across FOUR original AMD MathWorks executions, two distinct AMD EPYC processor models, both Ubuntu runner versions. This is 480 unique inputs replicated four times, not 1,920 independent inputs. Original Intel numerical parity and complete robustfit scale/SE/t, Yale pipeline parity remain unpassed.
