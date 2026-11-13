#!/usr/bin/env python3
"""Fail closed on incomplete/non-reproducible original R2026b diagnostic."""
import json
import sys

data = json.load(open(sys.argv[1]))
assert data["classification"] == "ORIGINAL_MATHWORKS_R2026B_V11_DISCLOSED_STUDENT_T_STAGES_ONLY"
assert data["release"] == "2026b" and data["mkl_cbwr"] == "COMPATIBLE"
assert data["max_num_comp_threads"] == 1
assert data["original_repetitions"] == 2 and data["original_case_count"] == 480
assert data["original_coef_count"] == 2 and data["original_source_unmodified"] is True
assert data["raw_input_sha256"] == "1144418910dc6a81ba3b98f9540fe914ac796d9a9bab25ce75f6c1ef2ace2f53"
rows = data["rows"]
assert len(rows) == 1920
for i in range(960):
    first, second = rows[i], rows[i + 960]
    assert first.pop("rep") == 1 and second.pop("rep") == 2
    assert first == second, (i, "non-reproducible genuine source")
    for k, value in first.items():
        if k.endswith("_hex"):
            assert isinstance(value, str) and len(value) == 16, (i, k)
    assert first["source_p_hex"] == first["source_tcdf_negative_hex"], i
    branch = ("source_betainc_upper_hex" if int(first["t_squared_hex"],16) < int(first["source_dfe_hex"],16)
              else "source_betainc_lower_hex")
    assert first["source_p_hex"] == first[branch], (i, branch)
print("Genuine original R2026b 480 × 2 coefficients × 2 passes repeat and branch exactly")
