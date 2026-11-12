# Original MATLAB R2026b three-host processor dispatch binary64 fingerprint

Three independently dispatched genuine licensed original MathWorks R2026b experiments repeated the identical *complete* 733,194 original `DGEMV` synthetic cancellation probes per host (all ordered placements of +2^53, -2^53 and +1 across 29,35,43,44,57,71; duplicate execution per probe). Original public QR and unchanged original robustfit R/h were separately executed uninstrumented and instrumented with full 144-record bitwise equality across ALL cases on each host. Each run exited normally with no vendor numerical probe overflow or repeat drift.

| Run | CPU | Complete original `DGEMV` binary64 733194-outcome SHA256 |
|---|---|---|
| [43260610828](https://github.com/sam-cingulum/cpm-matlab-reference-validation/actions/runs/43260610828) | AMD EPYC 9V74 80-core | `b5775b734f4d41147e4184bcb746a7eefffdeb9b6f2c3f97e93336f497239774` |
| [43260622683](https://github.com/sam-cingulum/cpm-matlab-reference-validation/actions/runs/43260622683) | AMD EPYC 9V45 96-core | `b5775b734f4d41147e4184bcb746a7eefffdeb9b6f2c3f97e93336f497239774` |
| [43260617316](https://github.com/sam-cingulum/cpm-matlab-reference-validation/actions/runs/43260617316) | Intel Xeon 6975P-C | **`c653ee0064ae7d216d95b116c3c2353d0b095490fd62dda1884bb276cf7664c4`** |

The earlier AMD EPYC 7763 run 43253897080 had the same canonical AMD fingerprint `b5775b...` as the two new AMD samples. This is now three distinct AMD processor models with source bit-for-bit equivalent vendor reduction topology, and one Intel model with a demonstrably different original BLAS arithmetic tree. Pinned original MATLAB/mkl shared libraries and environment settings are recorded in all runs. The raw original vendor output bytes are archived here; no proprietary library binary was copied or redistributed. None of this proves universal Intel or AMD CPU architecture equivalence. Results reflect these specifically observed execution profiles.

Detailed Intel versus AMD arithmetic tree reconstructions are maintained independently in Cingulum CPM. Intel Xeon 6975P-C *is not identical* to the Xeon Platinum 8370C earlier observed in run 43257619147. Further independent Intel run with identical exact original input remains required to match tree to 8370C.
