#!/usr/bin/env python3
"""V449 SOURCE-DISCLOSED original-only shape dispatch experiment.

Deterministic subset of source-only V441 inputs. Does not read any MATLAB
numerical original results or Rust numerical forecasts. All original MATLAB
execution and scoring kept in separately SHA-custodied evidence stages.
"""
from pathlib import Path
import hashlib
import json

HERE=Path(__file__).resolve().parent
V441=HERE.parent/"multix_v441_original_only_hidden_panel_cancellation"/"input.json"
V441_SHA="fd6422211331eb71c6609e251ffb50a69b9c3a2338c077fd388f972e3b492457"
KEEP=("unit_r02","unit_r15","unit_r16","unit_r23","unit_r24","unit_r31",
      "unit_r32","unit_r33","ulp_cancel_r16_r17","ulp_cancel_r31_r32",
      "alternating_dyadic","alternating_ulp")
WIDTHS=[1,2,11,12,13,16]
PADDING=list(range(17))
CLASS="V449_SOURCE_DISCLOSED_R2026B_ORIGINAL_ONLY_PADDED_ROW_STRIDE_DISPATCH"

def sha(b):return hashlib.sha256(b).hexdigest()

def main():
    data=V441.read_bytes()
    assert sha(data)==V441_SHA
    original=json.loads(data)
    assert original["V12"]=="SEALED"
    assert not original["original_MATLAB_numerical_outputs_read"]
    assert len(original["matrices"])==8 and len(original["cases"])==320
    rows=[r for r in original["cases"] if r["probe"] in KEEP]
    assert len(rows)==96
    for m in original["matrices"]:
        own=[r for r in rows if r["matrix_id"]==m["id"]]
        assert [r["probe"] for r in own]==list(KEEP)
    src={
        "classification":CLASS,
        "source_only":True,
        "NOT_new_original_firstblind":True,
        "original_MATLAB_numerical_outputs_read":False,
        "independent_Rust_outputs_read":False,
        "source_V441_input_SHA256":V441_SHA,
        "seed":202611230449,
        "V12":"SEALED",
        "matrix_count":8,"case_count":len(rows),
        "padding":PADDING,"widths":WIDTHS,
        "expect_two_original_repetitions":True,
        "matrices":original["matrices"],"cases":rows,
    }
    out=(json.dumps(src,sort_keys=True,separators=(",",":"))+"\n").encode()
    (HERE/"input.json").write_bytes(out)
    d=sha(out)
    (HERE/"input.sha256").write_text(d+"  input.json\n")
    print("V449 source input SHA",d,"cases",len(rows),"original panels per repetition",len(rows)*len(WIDTHS)*len(PADDING))
if __name__=="__main__":main()
