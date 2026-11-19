"""Finite full-rank pairs with controlled covariance ratios and independent group shifts."""
import hashlib
import json
import math
import random
import struct
from pathlib import Path

rng = random.Random(12583091)
cases = []
for j in range(48):
    n1 = (15, 28, 51, 74, 95, 129, 151)[j % 7]
    n2 = (17, 36, 59, 83, 111)[j % 5]
    slope = (0., .5, 1., 1.45, 1.56, 1.7, 2.5, 4.)[j % 8] * (-1)**j
    groups = []
    for group, n in enumerate((n1, n2)):
        x = [rng.gauss(0., 1.) for _ in range(n)]
        y = [slope * v + rng.gauss(0., .35 + .2 * (j % 4)) for v in x]
        x = [v + group * ((j % 5) * .125) for v in x]
        groups.append((y, x) if j % 3 == 2 else (x, y))
    values = [struct.pack(">d", v).hex() for k in range(2) for group in groups for v in group[k]]
    cases.append(dict(id=f"pivot_{j}", n1=n1, n2=n2, x=values))
folder = Path(__file__).parent
xvals = {0., *[2.**k for k in range(-60, 8)]}
for x in (.125, .25, .5, math.log(2), 1., 1.5, 2., 3., 4., 8., 16., 32., 36., 37.):
    xvals.update((math.nextafter(x, 0), x, math.nextafter(x, math.inf)))
for _ in range(160):
    xvals.add(2.**rng.uniform(-10., 5.5))
manifest = []
for name, data in [('input.json', cases), ('gamma.json', [struct.pack(">d", v).hex() for v in sorted(xvals)])]:
    buf = (json.dumps(data, separators=(",", ":")) + "\n").encode()
    (folder/name).write_bytes(buf)
    manifest.append(hashlib.sha256(buf).hexdigest()+"  "+name)
(folder/"input.sha256").write_text("\n".join(manifest)+"\n")
