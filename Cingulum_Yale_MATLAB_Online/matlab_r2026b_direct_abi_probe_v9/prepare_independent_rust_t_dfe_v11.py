#!/usr/bin/env python3
"""Publish only independent, SOURCE-DISCLOSED native Rust t/dfe inputs for R2026b.

No MATLAB numerical outputs or intermediate values enter the independent Rust
forecast. The resulting input-only dataset can be consumed in an authenticated
MATLAB research runner and by the vendor ABI for identical source-disclosed
comparison, but is not a sealed source-unseen certification.
"""
from __future__ import annotations
import argparse,gzip,hashlib,json,pathlib
FROZEN_NATIVE_RUST_SHA="efc63f5d1aeb979495bfe3d070c0bfe5d5be63a3386e47a5b7e029fdf6026f71"
def sha(b):return hashlib.sha256(b).hexdigest()
def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--native-rust-forecast",type=pathlib.Path,required=True)
    ap.add_argument("--output",type=pathlib.Path,required=True)
    x=ap.parse_args()
    raw=gzip.decompress(x.native_rust_forecast.read_bytes())
    assert sha(raw)==FROZEN_NATIVE_RUST_SHA,sha(raw)
    original=json.loads(raw)
    assert original["genuine_original_oracle_executed"] is False
    assert original["source_values_supplied_to_rust"] is False
    rows=[]
    for a in original["predictions"]:
        assert len(a["t_hex"])==2
        assert len(a["dfe_hex"])==16
        assert int(a["n"])>=4
        rows.append({"id":a["id"],"n":a["n"],"t_hex":a["t_hex"],"dfe_hex":a["dfe_hex"]})
    assert len(rows)==480
    obj={
       "classification":"SOURCE_DISCLOSED_INDEPENDENT_RUST_V11_T_DFE_INPUTS_ONLY_FOR_ORIGINAL_R2026B_ABI_RESEARCH",
       "source_unseen_V12":"NOT_GENERATED",
       "original_MATLAB_reference_numeric_values_used_to_generate":False,
       "source_numeric_outputs_supplied_to_compiled_Rust":False,
       "native_Rust_predictor_decompressed_sha256":FROZEN_NATIVE_RUST_SHA,
       "raw_case_count":480,"coefficient_count":960,
       "oracle_repetitions_expected":2,
       "rows":rows
    }
    out=json.dumps(obj,indent=2,sort_keys=True)+"\n"
    x.output.parent.mkdir(parents=True,exist_ok=True)
    x.output.write_text(out)
    print("RUST_ONLY_V11_SOURCE_DISCLOSED_INPUT_SHA",sha(out.encode()))
    print("RUST_ONLY_V11_COEFFICIENTS",2*len(rows))
    print("NONE_OF_960_RUST_T_VALUES_CAME_FROM_ORIGINAL_MATLAB")
if __name__=="__main__":main()
