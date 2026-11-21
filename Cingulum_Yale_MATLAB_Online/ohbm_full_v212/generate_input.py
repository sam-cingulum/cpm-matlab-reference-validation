"""V212: fresh prospective original OHBM all-four-method stress cohorts.

Finite symmetric edges, constant features, sparse outlier shifts, tied ranks,
mixed covariate columns and varying fold populations. Inputs are independent
of original MATLAB output and any previously frozen OHBM validation cohort.
"""
import hashlib
import json
import random
from pathlib import Path

cases = []
sizes = ((27, 5), (35, 7), (43, 6), (57, 7), (69, 5), (87, 8))
for option, selection in enumerate(
    ("pearson", "spearman", "robust_edgewise", "partial_correlation"), 1
):
    for trial, (n, d) in enumerate(sizes):
        rng = random.Random(2123107 + option * 131 + trial * 19)
        # Repeated outcome values stress Spearman ties and rank changes
        # across leave-one-out folds while remaining finite nonconstant.
        y = [
            (rng.randint(-53, 53) / 8) *
            (1.25 if trial % 2 else 0.75)
            for _ in range(n)
        ]
        cov = [
            [rng.randint(-61, 61) / 16 for _ in range(min(1 + trial, 5))]
            for _ in y
        ]
        mats = []
        for subject, outcome in enumerate(y):
            m = [[0.0] * d for _ in range(d)]
            for j in range(d):
                for i in range(j + 1):
                    weight = (0, -0.78125, 0.9375, 0, .34375)[(i + 2*j) % 5]
                    val = weight * outcome + rng.randint(-73, 73) / 32
                    if option == 2:
                        val = round(val * (4 if trial % 2 else 2)) / (
                            4 if trial % 2 else 2
                        )
                    m[i][j] = m[j][i] = val
            # Challenge rank-one folds and constant edge selection.
            for i, j, v in (
                (0, 1, -0.0), (1, 2, -1.0), (0, 3, -2.0),
                (2, 3, .75 + (subject == n - 1 - trial) * 1.0)
            ):
                m[i][j] = m[j][i] = v
            mats.append(m)
        cases.append(dict(
            id=f"ohbm_v212_fs{option}_trial{trial}",
            option=option,
            request=dict(
                selection=selection, subject_matrices=mats,
                outcomes=y, covariates=cov,
                p_threshold=0.046875 if trial % 3 else 0.09375
            )
        ))
assert len(cases)==24
assert len({q["id"] for q in cases})==24
out=Path(__file__).with_name("input.json")
out.write_text(json.dumps(cases,separators=(",",":"))+"\n")
out.with_suffix(".sha256").write_text(
    hashlib.sha256(out.read_bytes()).hexdigest()+"  input.json\n"
)
print("V212 new independent OHBM source-unseen 24 input SHA:",hashlib.sha256(out.read_bytes()).hexdigest())
