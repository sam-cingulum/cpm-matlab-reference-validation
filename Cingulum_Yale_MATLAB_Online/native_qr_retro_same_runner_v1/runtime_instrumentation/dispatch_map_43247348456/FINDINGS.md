# Genuine MATLAB R2026b active QR and BLAS dispatch, same-runner zero-bit disturbance

Genuine licensed MathWorks CI [run 43247348456](https://github.com/sam-cingulum/cpm-matlab-reference-validation/actions/runs/43247348456). **All 144 original 48-case x three-repetition full `qr` R, original `robustfit` R/h and pivots are identical between uninstrumented and read-only dispatch-traced MATLAB executions**. Both exited normally. The probe recorded 3,121 true original `dgeqp3_` calls in the MATLAB executable.

This probe reads **the real resolved BLAS/LAPACK function-pointer vectors**, not just symbol names or binding events. Their targets all reside in MathWorks bundled, unmodified `mkl.so`:

| Actual vector | Real target | Original vendor `mkl.so` DSO offset |
|---|---|---|
| `dgeqp3_vector` | `DGEQP3` | `0x397790` |
| `dlarfg_vector` | `dlarfg_64` | `0x385340` |
| `dlarf_vector` | `dlarf` | `0x3854d0` |
| `dgemv_vector` | `DGEMV_64` | `0x440d40` |
| `dger_vector` | `DGER_64` | `0x4409c0` |
| `ddot_vector` | `ddot_64_` | `0x441080` |
| `dnrm2_vector` | `dnrm2_64` | `0x440830` |
| `dscal_vector` | `dscal_64_` | `0x4402e0` |

The execution was on an **Intel Xeon 6975P-C**, whereas matched historical run 43237581220 executed on an **AMD EPYC 9V74**. The 48-case control records differ between those runs, despite exact within-run repeatability and matching MATLAB binary hashes. This is an identified **cross-execution numerical reproducibility issue**, not yet proof that CPU identity causes it. No MathWorks proprietary binary was modified, copied or redistributed. The dispatch map contains only symbol names, provider DSO basenames and numeric offsets.

## Scientific consequence

MATLAB's backend is an actual separate ILP64 vendor MKL build. Native oneAPI MKL results from a distinct release/host are **not** a reliable exact stand-in for the vendor reduction tree. The next experiment should compare MathWorks' public BLAS-facing `dlarf` / `dgemv` calls to full source `dgeqp3_` on **the same physical runner** before implementing the observed second-column update order in Rust. The reference MathWorks R/h remains authoritative and the pure-Rust native full-QR parity certification gate remains closed.
