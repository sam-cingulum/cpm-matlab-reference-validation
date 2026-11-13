#!/usr/bin/env python3
"""Verify exact two-pass original-source disclosure, not Rust forecast parity."""
import json
import sys

d = json.load(open(sys.argv[1]))
assert d["classification"] == "ORIGINAL_MATHWORKS_R2026B_V11_DISCLOSED_FORENSICS_ONLY"
assert d["release"] == "2026b" and d["mkl_cbwr"] == "COMPATIBLE"
assert d["max_num_comp_threads"] == 1 and d["case_count"] == 480 and d["repetitions"] == 2
assert d["original_robustfit_unchanged"] is True
rows = d["records"]
assert len(rows) == 960
fields = ["beta_hex", "covb_col_major_hex", "coeffcorr_col_major_hex", "se_hex",
          "t_hex", "p_hex", "resid_hex", "rstud_hex", "dfe_hex",
          "tcdf_negative_twosided_hex", "tcdf_positive_complement_twosided_hex",
          "betainc_twosided_hex", "betainc_complement_small_hex",
          "betainc_upper_small_hex", "betainc_complement_scaled_hex",
          "Rtol_col_major_hex", "original_fieldnames"]
for i in range(480):
    a, b = rows[i], rows[i + 480]
    assert a["original_rep"] == 1 and b["original_rep"] == 2
    assert a["id"] == b["id"] and a["n"] == b["n"]
    for field in fields:
        assert field in a and field in b, (i, field)
        assert a[field] == b[field], (i, field, "nonrepeatable original")
    for field, n in (("beta_hex", 2), ("covb_col_major_hex", 4),
                     ("coeffcorr_col_major_hex", 4), ("se_hex", 2),
                     ("t_hex", 2), ("p_hex", 2),
                     ("resid_hex", a["n"]), ("rstud_hex", a["n"])):
        assert len(a[field]) == n, (i, field, n)
    assert len(a["original_fieldnames"]) >= 15
print("GENUINE DISCLOSED R2026b original fields repeat exactly for 480 / 480 cases")
