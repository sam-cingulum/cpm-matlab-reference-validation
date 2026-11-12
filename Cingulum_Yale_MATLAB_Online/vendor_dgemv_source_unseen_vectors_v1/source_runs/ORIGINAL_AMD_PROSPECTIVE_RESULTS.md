# Genuine R2026b original MathWorks DGEMV 480 source-unseen binary64 inputs, source control

The **same** independently compiled and frozen pure-Rust AMD eight-lane and Intel sixteen-lane DGEMV binary64 forecast was cryptographically committed/pushed in **private `cingulum-cpm` commit `e00a8840b33e849e135de628eb54be001a094376`** **before any original source test run**. Original input SHA256 `d82b8f0537918b8f1f7190329830b8a963df2889d19f33b1f4bc37977a8cc670`. Precommitted two-profile prediction SHA256 `7e904510378f6e6cd6811a9b9ac1712dfbb34e94e0ff3cc9fe89933f73f375dd`.

Each genuine licensed MathWorks R2026b execution ran exact original `DGEQP3`/`robustfit` unmodified with an uninstrumented A-side, and again with original bundled vendor `DGEMV` invoked only on 480 unrelated scratch-vector pairs, 40 vector lengths, 12 numerical families. Every 144-record public QR/robustfit R/h output stayed bitwise equal A versus B, original real vendor dots evaluated twice with no drift, MATLAB returned normally. All raw numerical results and exact MATLAB CPU/library hashes are archived in subfolders here.

| Actual original run | Physical CPU | AMD source-blind Rust exact | Intel source-blind Rust exact |
|---|---|---|---|
| [43263348812](https://github.com/sam-cingulum/cpm-matlab-reference-validation/actions/runs/43263348812) | AMD EPYC 9V74 | **480/480** | 169/480 |
| [43263397233](https://github.com/sam-cingulum/cpm-matlab-reference-validation/actions/runs/43263397233) | AMD EPYC 7763 | **480/480** | 169/480 |
| [43263403686](https://github.com/sam-cingulum/cpm-matlab-reference-validation/actions/runs/43263403686) | AMD EPYC 7763 | **480/480** | 169/480 |

The **480/480** AMD matched independent numerical forecasts were source-unseen, meaning the AMD native Rust `DGEMV` component is prospectively exactly reproducible across 40 new input lengths and 12 predictor/vector families on these measured original MATLAB execution profiles. This is not complete end-to-end QR/robustfit parity. Original Intel CPU-profile tests are pending and should be scored under the *same frozen* independent Rust forecast before claiming prospective Intel parity. No MATLAB proprietary binaries have been copied, patched or redistributed.

## Additional independent original-source repetitions

Four more original MathWorks runs were executed under the **same frozen input and pure-Rust predictions**, with the same A/B source bitwise noninterference gates and true vendor `DGEMV` duplicate-result agreement. They all passed:

| Genuine run | Original CPU | Frozen AMD pure Rust | Frozen Intel pure Rust |
|---|---|---|---|
| [43264083899](https://github.com/sam-cingulum/cpm-matlab-reference-validation/actions/runs/43264083899) | AMD EPYC 9V74 | **480/480** | 169/480 |
| [43264089162](https://github.com/sam-cingulum/cpm-matlab-reference-validation/actions/runs/43264089162) | AMD EPYC 9V74 | **480/480** | 169/480 |
| [43264096153](https://github.com/sam-cingulum/cpm-matlab-reference-validation/actions/runs/43264096153) | AMD EPYC 9V74 | **480/480** | 169/480 |
| [43264102676](https://github.com/sam-cingulum/cpm-matlab-reference-validation/actions/runs/43264102676) | AMD EPYC 7763 | **480/480** | 169/480 |

**Total 7 independent licensed original MATLAB host executions, 3,360 source-unseen DGEMV results, AMD pure Rust exact 3,360/3,360.** Vendor arithmetic source control remains 100% bitwise identical to original `qr`/`robustfit` when traced and uninstrumented on each host. The CPU scheduler for these seven prospective runs selected AMD; **there is no original Intel-source prospective 480-case result yet**, and Intel parity MUST NOT be claimed from these seven AMD outcomes.
