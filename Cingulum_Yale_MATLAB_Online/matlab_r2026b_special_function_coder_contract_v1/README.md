# R2026b special-function MATLAB Coder experiment, licence gated

This folder contains **user-authored scalar entrypoints only**, not proprietary generated C source.

The purpose is to produce an authorized independent compiled-C **candidate mathematical implementation** of the actual original R2026b operations, and test its output bits against the original MATLAB interpreter. **Generated C is not assumed bitwise identical.** Pure Rust parity remains a separate stricter gate.

The genuine R2026b public GitHub-hosted MATLAB runner reported no MATLAB Coder installation and `license('test','MATLAB_Coder') == 0`, so **this experiment is NOT EXECUTABLE on that runner**. The licensed generation script fails closed rather than bypassing entitlements. The licence check is deliberately a precondition and never calls `codegen` if unavailable.

When the owner has **a legitimately licensed R2026b MATLAB Coder installation** in a private workspace:

1. Change to this directory within MATLAB so the user-authored scalar entrypoint is on the path.
2. Set a **private output directory outside the public repository**.
3. Call `run_codegen_only_if_licensed_v1('/private/authorized/coder-output')`. The script checks the installed licence and generates source-only code with three scalar binary64 inputs; it never embeds the original V7/V10/V11 outputs.
4. Build the generated code with an appropriate compiler under its applicable terms, then collect raw IEEE-754 output bits from **the generated compiled program** for all published V7/V10 raw cases.
5. Compare strict zero-tolerance results against the authenticated original interpreter. **If generated code fails even one original bit, it is not the original compatibility algorithm.**
6. If a *single* generated implementation genuinely passes all original disclosed cases, independently implement its general mathematical algorithm in pure Rust and run the complete V11 1,920/1,920 p-element and 960/960 whole-fit acceptance gates. No C libraries, foreign-runtime calls or source-answer lookup may be used in that final pure Rust implementation.

The supported built-ins are `betainc` and `gammaln`. MATLAB documentation notes Coder-generated `betainc` may use complex output types, so compare the exact real IEEE-754 component, not merely a decimal string. The MathWorks runtime version, CPU model, generated-source licence terms, original/generator codegen commits and hashes must be preserved in the private test manifest.

**Classification: source-disclosed implementation-acquisition scaffold; no Coder licence, no generated C, no source-unseen V12, no numerical parity certificate.**
