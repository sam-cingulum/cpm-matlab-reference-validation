#!/usr/bin/env python3
"""Rigorous offline replay of FIVE genuine MATLAB R2026b V10 AMD source archives.

Independently prospective SOURCE-DISCLOSED source, not sealed V12. Every
repetition and every source field is checked using the source-frozen schema,
numeric byte hashes and original CPU/vendor fingerprints. Falsification of
the beta-mean tail branch causes failure, with original bytes preserved.
"""
from __future__ import annotations
from pathlib import Path
import gzip,hashlib,json,struct
from verify_original_beta_mean_switch_v10_disclosed import checked_input,validate
ROOT=Path(__file__).resolve().parent
SOURCE_SHA="31eaf8fe894d6148f19ffe9507e1b006e27469cf8374454a6c9d5dc6c7d9a406"
INPUT_SHA="ed1b3af2b864241caa9719a3dc8ceb2df670c0a9bf426cf741d5959d60adedc5"
PUBHEAD="c962cca40aefff5e9ef7f2039ffb9a87e57d37cf"
RUSTHEAD="554356c59d9fa7751fb4a8551b253bebed9e0e85"
EXPECTED=[
    ("43680645835","AMD EPYC 9V74"),
    ("43680708790","AMD EPYC 7763"),
    ("43680710854","AMD EPYC 7763"),
    ("43680712985","AMD EPYC 9V74"),
    ("43680715477","AMD EPYC 9V45")
]
def sha(x:bytes)->str:return hashlib.sha256(x).hexdigest()
def fromhex(s:str)->float:return struct.unpack(">d",bytes.fromhex(s))[0]
def hx(x:float)->str:return struct.pack(">d",x).hex()
def verify_source_branch(s:dict)->dict:
    scores={"left_total":0,"left_exact":0,"right_total":0,"right_exact":0,
            "original_betaln_equal_composed":0,"original_student_p_equal_beta":0}
    for r in s["beta"][:s["beta_count"]]:
        a,b,x=(fromhex(r[k]) for k in ("a_hex","b_hex","x_hex"))
        lower=fromhex(r["lower_hex"]);upper=fromhex(r["upper_hex"])
        scores["original_betaln_equal_composed"]+=r["betaln_hex"]==r["composed_betaln_hex"]
        if x<a/(a+b):
            scores["left_total"]+=1
            scores["left_exact"]+=r["upper_hex"]==hx(1-lower)
        else:
            scores["right_total"]+=1
            scores["right_exact"]+=r["lower_hex"]==hx(1-upper)
    for row in s["student"][:s["student_count"]]:
        scores["original_student_p_equal_beta"]+=row["two_tcdf_hex"]==row["piecewise_tail_hex"]
    assert (scores["left_total"],scores["right_total"])==(1460,1352)
    assert scores["left_exact"]==scores["left_total"],scores
    assert scores["right_exact"]==scores["right_total"],scores
    assert scores["original_betaln_equal_composed"]==2812,scores
    assert scores["original_student_p_equal_beta"]==208,scores
    return scores
def main():
    raw=(ROOT/"input.json").read_bytes()
    assert sha(raw)==INPUT_SHA
    inp=checked_input()
    manifest=json.loads((ROOT/"SOURCE_ORIGINAL_SHA256_PROVENANCE_MANIFEST.json").read_bytes())
    assert manifest["published_input_sha256"]==INPUT_SHA
    assert manifest["original_genuine_numeric_sha256"]==SOURCE_SHA
    assert manifest["original_source_runner_precommit"]==PUBHEAD
    assert manifest["independent_Rust_preoriginal_forecast_commit"]==RUSTHEAD
    assert manifest["source_unseen_V12"]=="NOT_GENERATED"
    assert len(manifest["runs"])==len(EXPECTED)==5
    reference=None
    for (id,model),entry in zip(EXPECTED,manifest["runs"]):
        assert entry["run_id"]==id and entry["cpu"]==model
        assert entry["source_original_sha256"]==SOURCE_SHA
        collected={}
        for key,descriptor in entry["archives"].items():
            packed=(ROOT/descriptor["path"]).read_bytes()
            assert sha(packed)==descriptor["compressed_sha256"]
            collected[key]=gzip.decompress(packed)
            assert sha(collected[key])==descriptor["original_sha256"]
        original=collected["original"];cpu=collected["cpu"]
        assert sha(original)==SOURCE_SHA
        assert sha(cpu)==entry["cpu_vendor_sha256"]
        assert model.encode() in cpu and ("Commit="+PUBHEAD).encode() in cpu
        checks={}
        for line in collected["runner_manifest"].decode().strip().splitlines():
            value,name=line.split(maxsplit=1)
            checks[Path(name).name]=value
        assert checks["original_beta_mean_switch_v10_disclosed.json"]==SOURCE_SHA
        assert checks["cpu_and_original_vendor.txt"]==sha(cpu)
        assert checks["input.json"]==INPUT_SHA
        result=json.loads(original)
        validate(result,inp)
        if reference is None:reference=original
        assert reference==original,(id,"genuine original differs across AMD source")
        print("VALID V10",id,model,"two original repetitions; full source SHA",SOURCE_SHA)
    invariants=verify_source_branch(json.loads(reference))
    print("SOURCE-ONLY PROSPECTIVE V10 ORIGINAL BRANCH HYPOTHESES",invariants)
    print("5 genuine MATLAB R2026b original AMD host runs identical; V12 NOT GENERATED")

if __name__=="__main__":
    main()
