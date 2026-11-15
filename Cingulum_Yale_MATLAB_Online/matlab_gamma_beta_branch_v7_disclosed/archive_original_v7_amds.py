#!/usr/bin/env python3
"""Permanently archive unchanged original R2026b V7 artifacts from 3 AMD hosts.

Only checks source provenance, hashes & repeats; does not score Rust.
Never invoke MATLAB or mutate/overwrite original downloaded raw output.
Archives contain no patient/clinical data. Public SHA manifest is immutable
once committed. Do not rewrite after source scoring or next iterations.
"""
from pathlib import Path
import gzip
import hashlib
import json

ROOT=Path(__file__).resolve().parent
SOURCE_ROOT=ROOT/"source_runs"
SOURCE_SHA="3b8ba0b61812aaff6a943fe50b5bfc3364aac2f0b262ba4fba2a89a4c1f586a2"
INPUT_SHA="60ef98bbe1d779ef4d79e7d82c9c3c51d2b2c8b14b79be158574d437c058e233"
PREORIGINAL_PUBLIC="ed031bd3897573defc4d3ddde1f7970fc5e9747a"
PREORIGINAL_PRIVATE="30d2f78bc04d578728f73d2f39556027377c94ab"
IDS={"43678433690":"AMD EPYC 7763",
     "43678440057":"AMD EPYC 9V45",
     "43678436063":"AMD EPYC 9V74"}
ARTIFACT="genuine-R2026b-SOURCE-DISCLOSED-gamma-beta-branch-v7-disclosed"
FILES={"original":"original_gamma_beta_branch_v7_disclosed.json",
       "cpu":"cpu_and_original_vendor.txt",
       "original_manifest":"original_sha256_manifest.txt"}

def sha(blob:bytes)->str:
    return hashlib.sha256(blob).hexdigest()

def main()->None:
    assert sha((ROOT/"input.json").read_bytes())==INPUT_SHA
    manifest={
       "classification":"THREE_GENUINE_ORIGINAL_MATHWORKS_R2026B_SOURCE_DISCLOSED_V7_AMD_CROSSRUN_BYTE_IDENTICAL",
       "source_unseen_V12":"NOT_GENERATED",
       "input_sha256":INPUT_SHA,
       "public_original_runner_precommit":PREORIGINAL_PUBLIC,
       "native_private_preoriginal_forecast_commit":PREORIGINAL_PRIVATE,
       "genuine_original_numeric_sha256":SOURCE_SHA,
       "runs":[]
    }
    for runid,model in IDS.items():
        directory=SOURCE_ROOT/runid/ARTIFACT
        assert directory.is_dir(),f"missing original source run {runid}"
        original=(directory/FILES["original"]).read_bytes()
        cpu=(directory/FILES["cpu"]).read_bytes()
        assert sha(original)==SOURCE_SHA
        assert model.encode() in cpu
        assert ("Commit="+PREORIGINAL_PUBLIC).encode() in cpu
        assert b"mkl" in cpu or b"MKL" in cpu
        original_man=(directory/FILES["original_manifest"]).read_text()
        expected={}
        for line in original_man.strip().splitlines():
            a,name=line.strip().split(maxsplit=1)
            expected[Path(name).name]=a
        assert expected[FILES["original"]]==SOURCE_SHA
        assert expected[FILES["cpu"]]==sha(cpu)
        assert expected["input.json"]==INPUT_SHA
        output_dir=SOURCE_ROOT/runid
        provenance={
            "run":runid,"cpu":model,
            "original_sha256":SOURCE_SHA,
            "input_sha256":INPUT_SHA,
            "original_vendor_cpu_sha256":sha(cpu),
            "archived":{}
        }
        for kind,name in FILES.items():
            raw=(directory/name).read_bytes()
            outfile=output_dir/(name+".gz")
            packed=gzip.compress(raw,mtime=0,compresslevel=9)
            if outfile.exists():
                assert outfile.read_bytes()==packed,"existing archive must not be overwritten"
            else:
                outfile.write_bytes(packed)
            assert gzip.decompress(outfile.read_bytes())==raw
            provenance["archived"][kind]={
                "path":str(outfile.relative_to(ROOT)),
                "uncompressed_sha256":sha(raw),
                "compressed_sha256":sha(packed)
            }
        manifest["runs"].append(provenance)
    dest=ROOT/"SOURCE_ORIGINAL_SHA256_PROVENANCE_MANIFEST.json"
    result=json.dumps(manifest,sort_keys=True,indent=2)+"\n"
    if dest.exists():
        assert dest.read_text()==result,"immutable source provenance manifest changed"
    else:
        dest.write_text(result)
    print("V7 original R2026b source archived across 3 AMD CPUs:",SOURCE_SHA)
    for row in manifest["runs"]:
        print(row["run"],row["cpu"],row["original_vendor_cpu_sha256"])

if __name__=="__main__":
    main()
