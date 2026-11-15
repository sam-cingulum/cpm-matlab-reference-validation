#!/usr/bin/env python3
"""Permanently archive 5 genuine original R2026b V10 source runs across 3 AMD models.

Source binaries and original numeric bytes are immutable; this checker never
changes original downloaded sources, only adds verified compressed copies.
V10 is prospectively source-disclosed, *not* new source-unseen V12.
"""
from __future__ import annotations
from pathlib import Path
import gzip,hashlib,json
ROOT=Path(__file__).resolve().parent
INPUT_SHA="ed1b3af2b864241caa9719a3dc8ceb2df670c0a9bf426cf741d5959d60adedc5"
SOURCE_SHA="31eaf8fe894d6148f19ffe9507e1b006e27469cf8374454a6c9d5dc6c7d9a406"
PUBHEAD="c962cca40aefff5e9ef7f2039ffb9a87e57d37cf"
RUSTHEAD="554356c59d9fa7751fb4a8551b253bebed9e0e85"
RUNS=[
    ("43680645835","AMD EPYC 9V74"),
    ("43680708790","AMD EPYC 7763"),
    ("43680710854","AMD EPYC 7763"),
    ("43680712985","AMD EPYC 9V74"),
    ("43680715477","AMD EPYC 9V45")
]
ART="genuine-R2026b-SOURCE-DISCLOSED-gamma-beta-mean-switch-v10-disclosed"
FILES={
 "original":"original_beta_mean_switch_v10_disclosed.json",
 "cpu":"cpu_and_original_vendor.txt",
 "runner_manifest":"original_sha256_manifest.txt"
}
def sha(blob:bytes)->str:return hashlib.sha256(blob).hexdigest()
def main():
    assert sha((ROOT/"input.json").read_bytes())==INPUT_SHA
    manifest={
        "classification":"V10_GENUINE_MATHWORKS_R2026B_PROSPECTIVE_SOURCE_DISCLOSED_AMD_CROSSRUN",
        "source_unseen_V12":"NOT_GENERATED",
        "original_source_runner_precommit":PUBHEAD,
        "independent_Rust_preoriginal_forecast_commit":RUSTHEAD,
        "published_input_sha256":INPUT_SHA,
        "original_genuine_numeric_sha256":SOURCE_SHA,
        "runs":[]
    }
    for id,model in RUNS:
        src=ROOT/"source_runs"/id/ART
        assert src.is_dir(),id
        original=(src/FILES["original"]).read_bytes()
        cpu=(src/FILES["cpu"]).read_bytes()
        assert sha(original)==SOURCE_SHA,(id,"original numeric mismatch")
        assert model.encode() in cpu,(id,"CPU mismatch")
        assert ("Commit="+PUBHEAD).encode() in cpu,(id,"preoriginal source commit changed")
        assert b"mkl" in cpu or b"MKL" in cpu
        raw_manifest=(src/FILES["runner_manifest"]).read_text()
        checks={}
        for line in raw_manifest.strip().splitlines():
            value,name=line.split(maxsplit=1)
            checks[Path(name).name]=value
        assert checks[FILES["original"]]==SOURCE_SHA
        assert checks[FILES["cpu"]]==sha(cpu)
        assert checks["input.json"]==INPUT_SHA
        entry={"run_id":id,"cpu":model,
               "source_original_sha256":SOURCE_SHA,
               "cpu_vendor_sha256":sha(cpu),"archives":{}}
        for k,name in FILES.items():
            raw=(src/name).read_bytes()
            packed=gzip.compress(raw,mtime=0,compresslevel=9)
            dst=ROOT/"source_runs"/id/(name+".gz")
            if dst.exists():assert dst.read_bytes()==packed,"existing source archive changed"
            else:dst.write_bytes(packed)
            assert gzip.decompress(dst.read_bytes())==raw
            entry["archives"][k]={
               "path":str(dst.relative_to(ROOT)),
               "original_sha256":sha(raw),
               "compressed_sha256":sha(packed)
            }
        manifest["runs"].append(entry)
    target=ROOT/"SOURCE_ORIGINAL_SHA256_PROVENANCE_MANIFEST.json"
    text=json.dumps(manifest,sort_keys=True,indent=2)+"\n"
    if target.exists():assert target.read_text()==text,"immutable original manifest changed"
    else:target.write_text(text)
    print("V10 genuine original R2026b NUMERIC SHA",SOURCE_SHA)
    for r in manifest["runs"]:
        print(r["run_id"],r["cpu"],r["cpu_vendor_sha256"])
    print("All 5 V10 source runs exactly identical across AMD 7763/9V45/9V74")

if __name__=="__main__":
    main()
