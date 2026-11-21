"""V198 original-blind out-of-distribution Yale Hotelling stress design.

Eight independent statistical regimes, three deterministic cases each, six
matrix dimensions; 144 unseen raw two-group data sets. No original MATLAB
outputs, pretrained tables or oracle forecasts are used to build inputs.

Regimes include disparate group sizes, correlated feature blocks,
heteroscedastic channels, large-offset cancellation, microscopic units,
outliers, and small near-square designs. All cases remain finite with
positive-definite model covariance by construction, but no claim is made
that source/native methods will match until genuine-original certification.
"""
import hashlib
import json
import random
import struct
from pathlib import Path

rng = random.Random(19822061)
bits = lambda x: struct.pack(">d", float(x)).hex()
cases = []
for width in range(1, 7):
    for regime in range(8):
        for repeat in range(3):
            j = len(cases)
            n1, n2 = (
                (19, 23), (17, 121), (84, 21), (51, 53),
                (25, 27), (95, 97), (11 + width, 14 + width), (36, 37)
            )[regime]
            groups = []
            for g, n in enumerate((n1, n2)):
                base = [rng.gauss(0.0, 1.0) for _ in range(n)]
                lat = [rng.gauss(0.0, 1.0) for _ in range(n)]
                cols = []
                for k in range(width):
                    channel = []
                    for idx in range(n):
                        fresh = rng.gauss(0.0, 1.0)
                        if regime == 0:
                            v = fresh + 0.22 * base[idx] - 0.37 * lat[idx] + g * (0.43 + 0.045 * repeat)
                        elif regime == 1:
                            v = fresh * (0.7 + 0.3 * g) + 0.65 * base[idx] + g * (0.2 + repeat * 0.15)
                        elif regime == 2:
                            # Full-rank but strongly correlated: near-common
                            # component, independent noise at a fixed scale.
                            v = (1.0 + k * 0.007) * base[idx] + fresh * 0.09 + g * (0.24 + 0.08 * repeat)
                        elif regime == 3:
                            scales = (1.0e-3, 7.0, 3.0e3, 2.5e-5, 90.0, 0.11)
                            v = scales[k] * (fresh + 0.28 * base[idx] + g * (0.35 + 0.04 * repeat))
                        elif regime == 4:
                            # Raw large common offset, small but representable
                            # biological-scale residuals, mixed signs.
                            sign = -1.0 if k % 2 else 1.0
                            v = sign * 1.0e6 + (0.03 + k * .002) * (fresh + .3 * base[idx] + .17 * g)
                        elif regime == 5:
                            scales = (1.0e-6, 1.0e-4, 0.006, 2.3, 1.7e-5, 30.0)
                            v = scales[k] * (fresh + .55 * lat[idx] + g * (0.32 + repeat * 0.06))
                        elif regime == 6:
                            spike = (14.0 if idx % 13 == 0 else -11.0 if idx % 17 == 0 else 0.0)
                            v = fresh + .42 * base[idx] + spike * ((-1.0) ** (idx + k)) + g * .4
                        else:
                            v = fresh + .58 * base[idx] - .33 * lat[idx] + g * (0.18 + repeat * 0.03)
                        channel.append(v)
                    cols.append(channel)
                groups.append(cols)
            samples = [
                bits(v)
                for k in range(width)
                for group in groups
                for v in group[k]
            ]
            assert len(samples) == (n1 + n2) * width
            cases.append(dict(
                id=f"hotelling_v198_{j}", width=width,
                n1=n1, n2=n2, x=samples
            ))
assert len(cases) == 144
assert len({c["id"] for c in cases}) == 144
path = Path(__file__).with_name("input.json")
path.write_text(json.dumps(cases, separators=(",", ":")) + "\n")
path.with_suffix(".sha256").write_text(
    hashlib.sha256(path.read_bytes()).hexdigest() + "  input.json\n"
)
print("V198 source-unseen high-stress input SHA:", hashlib.sha256(path.read_bytes()).hexdigest())
