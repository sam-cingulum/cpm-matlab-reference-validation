"""Preregister a genuinely NEW source-unseen Yale Hotelling V200 stress cohort.

Eight harder physical/numerical regimes, three repeats each, six dimensions.
The only source inputs here are deterministic Python PRNG draws and IEEE-754
raw subject matrices. No MATLAB observations, prior V198 case values or native
original answers are read to create the cohort. First original execution MUST
occur only after public inputs and private native forecasts/scorer are pushed.
"""
import hashlib
import json
import math
import random
import struct
from pathlib import Path

rng = random.Random(200261121)
bits = lambda x: struct.pack(">d", float(x)).hex()
cases = []

for width in range(1, 7):
    for regime in range(8):
        for repeat in range(3):
            case_number = len(cases)
            n1, n2 = (
                (8 + width, 11 + width),   # high variance with minimal residual degrees
                (64, 257),                # serious sample imbalance
                (37, 41),                # nearly common-mode, subtle full rank
                (47, 43),                # many decades of heteroscedastic feature scales
                (53, 57),                # common large-offset cancellation
                (96, 103),               # null-signal small probabilities
                (24 + width, 26 + width), # very large effects and tail CDF saturation
                (85, 67),                # clustered outliers and anti-correlated features
            )[regime]

            shared = [
                [rng.gauss(0.0, 1.0) for _ in range(n)]
                for n in (n1, n2)
            ]
            second = [
                [rng.gauss(0.0, 1.0) for _ in range(n)]
                for n in (n1, n2)
            ]
            groups = []
            for group, n in enumerate((n1, n2)):
                cols = []
                for k in range(width):
                    channel = []
                    for i in range(n):
                        independent = rng.gauss(0.0, 1.0)
                        common = shared[group][i]
                        latent = second[group][i]
                        if regime == 0:
                            v = independent + 0.35 * common - 0.24 * latent + group * (0.43 + repeat * 0.16)
                        elif regime == 1:
                            v = (0.4 + 1.15 * group) * independent + 0.4 * common + group * (0.18 + 0.17 * repeat)
                        elif regime == 2:
                            v = (1.0 + 0.03 * k) * common + (7.5e-4 + 1e-4 * repeat) * independent + group * 0.35
                        elif regime == 3:
                            scales = (3e-10, 5e5, 9e-5, 2e7, 6e-3, 80.0)
                            v = scales[k] * (independent + 0.13 * common + 0.06 * latent + group * (0.27 + 0.06 * repeat))
                        elif regime == 4:
                            offset = (-1 if k % 2 else 1) * (1e7 + k * 3e6)
                            v = offset + (0.008 + 0.003 * k) * (independent + 0.3 * common + group * 0.31)
                        elif regime == 5:
                            v = independent + 0.45 * common + 0.21 * latent + group * (0.001 + 0.002 * repeat)
                        elif regime == 6:
                            v = independent * 0.65 + 0.11 * common + group * (2.7 + repeat * 0.6)
                        else:
                            spike = 25 if i % 19 == 0 else -24 if i % 23 == 0 else 0
                            v = independent + (1 if k % 2 else -1) * 0.6 * common + spike * (0.3 + 0.07 * k) + group * 0.45
                        assert math.isfinite(v)
                        channel.append(v)
                    cols.append(channel)
                groups.append(cols)
            samples = [
                bits(v)
                for k in range(width)
                for group in groups
                for v in group[k]
            ]
            assert len(samples) == width * (n1 + n2)
            cases.append({
                "id": f"hotelling_v200_{case_number}",
                "width": width, "n1": n1, "n2": n2, "x": samples
            })

assert len(cases) == 144
assert len({x["id"] for x in cases}) == 144
path = Path(__file__).with_name("input.json")
path.write_text(json.dumps(cases, separators=(",", ":")) + "\n")
path.with_suffix(".sha256").write_text(
    hashlib.sha256(path.read_bytes()).hexdigest() + "  input.json\n"
)
print("V200 NEW raw source-only input SHA256:", hashlib.sha256(path.read_bytes()).hexdigest())
