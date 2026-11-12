# Genuine MATLAB R2026b: exhaustive historical 48-case internal Householder capture

## Original oracle and trace

- [Licensed MathWorks runner 43234972842](https://github.com/sam-cingulum/cpm-matlab-reference-validation/actions/runs/43234972842), completed successfully.
- Immutable original 48-case synthetic input JSON SHA256: `36f70d7cfd31da808f4c5f61f1127e292597097287a21248782723436f26fa1b`.
- Original MathWorks MATLAB executable calls **unmodified `dgeqp3_`** through an independently compiled `LD_PRELOAD` forwarding interposer. The interposer snapshots matrix buffer before and after the original numerical routine, Householder `tau`, both pivot positions, and info. No MATLAB binary or original numerical computation is modified.
- The complete matching **clean and instrumented MATLAB results** (both full R and leverage `h`, public QR R and pivot) have identical SHA256: `c36bd89e6e0979ac8e5df26d97cbe4f75370aca51ebc682d2f035007d9fe1544`.

## Acceptance results

- 48/48 historical synthetic cases matched to genuine original raw input, across all 29/35/43/44/57/71 observation sizes.
- 288/288 actual original `dgeqp3_` in-place numerical snapshots captured: public QR and original `robustfit` QR, three repetitions of each case.
- All 48 cases have **six completely bit-identical** original final Householder A buffers and both tau values.
- Every private output upper-triangular R entry and both pivot positions match the uninstrumented MATLAB public QR, including column-pivoted cases. Original MathWorks Fortran pivot ABI is 64-bit integers in this runner.
- 144 clean vs 144 instrumented complete MATLAB output records: zero binary64 differences across R matrices, leverage vectors, and pivots; both MATLAB processes exited normally.
- Zero buffer ring overflows, zero unmatched source-data buffers, zero differing original input vectors.

## Scope and caution

This is a **retrospective, source-disclosed historical numerical trace**. It captures genuine `dgeqp3_` input/output, tau, reflectors, and pivots, but **not yet the exact internal floating-point reduction order inside `dgeqp3_`**. No result here proves compiled Rust or novel prospective Yale/MATLAB parity. Use these source buffers only to diagnose independent implementation discrepancies, never as runtime corrections or substituted operands. The preexisting native Rust raw-input R/h acceptance result is unchanged pending independently executed tests.

The raw logs, input/output control JSON files, verification script, case-indexed SHA256 hashes and checksum manifest are archived together. SHA256 manifest is relative to this directory.
