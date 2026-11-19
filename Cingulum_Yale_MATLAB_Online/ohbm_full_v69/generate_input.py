"""Finite synthetic symmetric networks with fresh seeds and two outcome-linked signs."""
import hashlib
import json
import random
from pathlib import Path

cases = []
for option, selection in enumerate(("pearson", "spearman", "robust_edgewise", "partial_correlation"), 1):
    for trial, (n, d) in enumerate(((18, 4), (25, 5), (35, 6), (43, 4), (65, 6))):
        rng = random.Random(690000 + option * 113 + trial)
        y = [rng.randint(-40, 40) / 8 for _ in range(n)]
        cov = [[rng.randint(-51, 51)/16 for _ in range(1 + trial)] for _ in y]
        mats = []
        for outcome in y:
            m = [[0.] * d for _ in range(d)]
            for j in range(d):
                for i in range(j+1):
                    weight = (0, -0.8125, 1.1875, 0, .21875)[(i+2*j)%5]
                    v = weight*outcome + rng.randint(-65, 65)/32
                    if option == 2:
                        v = round(v*2)/2
                    m[i][j] = m[j][i] = v
            mats.append(m)
        cases.append(dict(id=f"v69_fs{option}_n{n}",option=option,
            request=dict(selection=selection,subject_matrices=mats,outcomes=y,covariates=cov,p_threshold=.0625)))
folder = Path(__file__).parent
out = folder / "input.json"
out.write_text(json.dumps(cases,separators=(",",":")) + "\n")
(folder / "input.sha256").write_text(hashlib.sha256(out.read_bytes()).hexdigest()+"  input.json\n")
