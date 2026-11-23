#!/usr/bin/env python3
"""V453 source-disclosed original-only repeated-16-block boundary experiment.

Extends V449's *source-defined*, numerical-output-free, 96-case inputs.
Never reads genuine MATLAB numerical outputs or Rust numerical forecasts.
"""
from pathlib import Path
import hashlib
import json

HERE=Path(__file__).resolve().parent
BASE=HERE.parent/"multix_v449_original_only_zero_padding_stride_switch"/"input.json"
BASE_SHA="e2fc94a01754901a2ff9da73f6b4f479857c126e5ce71e962e66fe0b92d4c079"
WIDTHS=[1,12,16]
PADDING=list(range(36))
CLASS="V453_SOURCE_DISCLOSED_R2026B_ORIGINAL_ONLY_REFLECTOR_BLOCK16_PERIODICITY"
def sha(b):return hashlib.sha256(b).hexdigest()

def main():
    raw=BASE.read_bytes()
    assert sha(raw)==BASE_SHA
    src=json.loads(raw)
    assert src["V12"]=="SEALED"
    assert src["NOT_new_original_firstblind"] and src["source_only"]
    assert not src["original_MATLAB_numerical_outputs_read"]
    assert not src["independent_Rust_outputs_read"]
    assert len(src["matrices"])==8 and len(src["cases"])==96
    out={
        "classification":CLASS,
        "source_only":True,
        "NOT_new_original_firstblind":True,
        "original_MATLAB_numerical_outputs_read":False,
        "independent_Rust_outputs_read":False,
        "V12":"SEALED","seed":202611230453,
        "V449_source_input_SHA256":BASE_SHA,
        "matrix_count":8,"case_count":96,
        "widths":WIDTHS,"padding":PADDING,
        "matrices":src["matrices"],"cases":src["cases"],
    }
    blob=(json.dumps(out,sort_keys=True,separators=(",",":"))+"\n").encode()
    (HERE/"input.json").write_bytes(blob)
    digest=sha(blob)
    (HERE/"input.sha256").write_text(digest+"  input.json\n")
    print("V453 input",digest,"cases",96,
      "widths",WIDTHS,"padding",[0,PADDING[-1]],"panels/repetition",96*len(WIDTHS)*len(PADDING))
if __name__=="__main__":main()
