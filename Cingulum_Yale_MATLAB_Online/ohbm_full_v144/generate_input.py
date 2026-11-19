"""Finite synthetic symmetric networks with constant edges and fold-dependent rank."""
import hashlib
import json
import random
from pathlib import Path

cases = []
for option, selection in enumerate(("pearson", "spearman", "robust_edgewise", "partial_correlation"), 1):
    for trial, (n, d) in enumerate(((17, 6), (26, 5), (37, 6), (54, 5), (83, 6))):
        rng = random.Random(1440000 + option * 113 + trial)
        y = [rng.randint(-40, 40) / 8 for _ in range(n)]
        cov = [[rng.randint(-51, 51)/16 for _ in range(1 + trial)] for _ in y]
        mats = []
        for subject, outcome in enumerate(y):
            m = [[0.] * d for _ in range(d)]
            for j in range(d):
                for i in range(j+1):
                    weight = (0, -0.8125, 1.1875, 0, .21875)[(i+2*j)%5]
                    v = weight*outcome + rng.randint(-65, 65)/32
                    if option == 2:
                        v = round(v*2)/2
                    m[i][j] = m[j][i] = v
            # Each cohort contains both intercept-only and slope-only rank-one fits.
            # The final chosen edge drops to rank one when its exceptional subject is held out.
            for i,j,value in [(0,1,-0.), (1,2,-1.), (0,3,-2.), (2,3,.75 + (subject == n-1-trial))]:
                m[i][j] = m[j][i] = value
            mats.append(m)
        cases.append(dict(id=f"v144_fs{option}_n{n}",option=option,
            request=dict(selection=selection,subject_matrices=mats,outcomes=y,covariates=cov,p_threshold=.0625)))
folder = Path(__file__).parent
out = folder / "input.json"
out.write_text(json.dumps(cases,separators=(",",":")) + "\n")
(folder / "input.sha256").write_text(hashlib.sha256(out.read_bytes()).hexdigest()+"  input.json\n")
