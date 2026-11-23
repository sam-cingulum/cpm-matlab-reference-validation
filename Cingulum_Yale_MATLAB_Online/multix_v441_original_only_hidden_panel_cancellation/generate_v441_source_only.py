#!/usr/bin/env python3
"""V441 pre-original, source-only cancellation challenge for MATLAB's hidden A\\B.

Build a deterministic input from SHA-pinned, source-DISCLOSED V377 matrices.
This is a geometry/reduction identification experiment, NOT first-blind proof.
No original MATLAB output, Rust numerical forecast, or oracle is read here.
"""
from pathlib import Path
import hashlib
import json
import math
import struct

HERE = Path(__file__).resolve().parent
SOURCE = HERE.parent / "multix_v377_post_v371_two_reflector_sparse_impulses/input.json"
SOURCE_SHA = "ef95b3a983d15454b6ca0e4625893039cc896b77fe792a2108166543301c1556"
CLASS = "V441_SOURCE_DISCLOSED_R2026B_TWO_REFLECTOR_CANCELLATION_ORIGINAL_ONLY"
WIDTHS = (1, 2, 11, 12, 13, 16)
PADDING = (0, 1, 7, 16)
SEED = 202611230441

def hx(v):
    assert math.isfinite(v)
    return struct.pack(">d",v).hex()

def probes_for(n):
    """RHS patterns target head, SIMD half boundaries, scalar tails and FMA."""
    out=[]
    # Zero-based rows 31/32 matter to a contiguous two-half n65 tree.
    # n48 boundary is 23/24, while both geometries exercise the 12-column panel.
    indices = list(dict.fromkeys(i for i in
        (1,2,3,14,15,16,22,23,24,29,30,31,32,n-5,n-4,n-3)
        if 0 <= i < n-1))
    for idx in indices:
        v=[0.0]*n;v[idx]=1.0
        out.append((f"unit_r{idx+1:02d}",v,"repeated"))
    pairs=[(1,2),(15,16),(22,23),(23,24),(29,30),(30,31),
           (31,32),(n-5,n-4),(n-4,n-3)]
    for i,j in dict.fromkeys(pairs):
        if j>=n-1:continue
        v=[0.0]*n;v[i]=1.0;v[j]=-1.0
        out.append((f"cancel_r{i+1:02d}_r{j+1:02d}",v,"repeated"))
        w=v.copy();w[j]=-(1.0+2.0**-52)
        out.append((f"ulp_cancel_r{i+1:02d}_r{j+1:02d}",w,"repeated"))
    v=[0.0]*n
    for i in range(1,n-1):
        v[i]=((-1.0)**i)*(2.0**((i%5)-3))
    out.append(("alternating_dyadic",v,"repeated"))
    out.append(("alternating_dyadic_sign_panel",v,"alternating_sign"))
    v=[0.0]*n
    v[1]=2.0**25;v[2]=-(2.0**25);v[3]=2.0**-23
    out.append(("head_large_cancel_repeated",v,"repeated"))
    v=[0.0]*n
    v[1]=2.0**25;v[2]=-(2.0**25);v[3]=2.0**-23
    out.append(("head_large_cancel_sign_panel",v,"alternating_sign"))
    v=[0.0]*n
    for i in range(2,n-1,2):v[i]=-0.0
    v[1]=1.0
    out.append(("signed_zero_lanes",v,"repeated"))
    v=[0.0]*n
    for i in range(1,n-1):
        v[i]=((-1.0)**i)*((1.0+2.0**-52) if i%3==0 else 1.0)
    out.append(("alternating_ulp",v,"repeated"))
    assert all(len(v)==n and v[-1]==0.0 for _,v,_ in out)
    assert len({id for id,_,_ in out})==len(out)
    return out

def main():
    raw=SOURCE.read_bytes()
    assert hashlib.sha256(raw).hexdigest()==SOURCE_SHA, "V377 source SHA custody"
    src=json.loads(raw)
    assert src["classification"]=="V377_POST_V371_SOURCE_DISCLOSED_ORIGINAL_ONLY_TWO_REFLECTOR_SPARSE_IMPULSES"
    assert src["V12"]=="SEALED"
    assert src["source_disclosed_after_V371"] and not src["original_MATLAB_numerical_results_consulted"]
    assert len(src["cases"])==8
    rows=[]
    matrices=[]
    specs={}
    for case in src["cases"]:
        n=int(case["n"]);p=int(case["p"])
        assert n in (48,65) and p in (9,10,11,12)
        assert len(case["a_colmajor_hex"])==n*p
        matrices.append({"id":case["id"],"n":n,"p":p,"a_colmajor_hex":case["a_colmajor_hex"]})
        specs[case["id"]] = len(probes_for(n))
        for probe, v, layout in probes_for(n):
            rows.append({
              "id":f"{case['id']}__{probe}",
              "matrix_id":case["id"],"probe":probe,"layout":layout,
              "b_colmajor_hex":[hx(x) for x in v],
            })
    assert all(len(row["b_colmajor_hex"])==next(m["n"] for m in matrices if m["id"]==row["matrix_id"]) for row in rows)
    doc={
      "classification":CLASS,"V12":"SEALED","seed":SEED,
      "source_disclosed_diagnostic":True,
      "new_original_firstblind_candidate":False,
      "original_MATLAB_numerical_outputs_read":False,
      "original_only_runner_reads_Rust_predictions":False,
      "original_V377_input_sha256":SOURCE_SHA,
      "n_values":[48,65],"p_values":[9,10,11,12],
      "widths":list(WIDTHS),"padding":list(PADDING),
      "matrix_count":8,"probe_count":len(rows),
      "probe_count_per_matrix":specs,"matrices":matrices,"cases":rows,
    }
    blob=(json.dumps(doc,sort_keys=True,separators=(",",":"))+"\n").encode()
    (HERE/"input.json").write_bytes(blob)
    sha=hashlib.sha256(blob).hexdigest()
    (HERE/"input.sha256").write_text(f"{sha}  input.json\n")
    print("SOURCE_INPUT_SHA256",sha,"matrix cases",8,"challenge probes",len(rows),
          "MATLAB solves per repetition",len(rows)*len(WIDTHS)*len(PADDING))
if __name__=="__main__":
    main()
