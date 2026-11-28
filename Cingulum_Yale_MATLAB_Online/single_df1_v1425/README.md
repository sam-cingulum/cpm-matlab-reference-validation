# V1425 single arctangent and Cauchy tail validation

This source-disclosed probe measures original MATLAB R2026b Update 1 on AMD
EPYC 7763 and 9V45 using one thread and MKL CBWR COMPATIBLE. It generates
binary32 arctangent inputs independently of V1424 with a fresh seed, coverage
at every finite exponent and denser samples around the main reduction ranges.
It also measures both Yale t-statistic associations and their two-sided p-values
for signed binary32 correlations with one degree of freedom. The binary dumps
preserve signs, NaN payloads, infinities and subnormals. The workflow verifies the
MathWorks mathspec binary hash and checks the two repetitions byte for byte.
