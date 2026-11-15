#!/usr/bin/env python3
"""Replay complete permanently archived original MATLAB R2026b V7 3-AMD evidence.

No MATLAB licence or native Rust required for archival verification.
Source runs are genuine and were executed after public raw-input precommit
and private original-blind Rust precommit. Source-disclosed, NOT V12.
"""
from __future__ import annotations
import gzip
import hashlib
import json
from pathlib import Path
from verify_original_gamma_beta_branch_v7_disclosed import checked_input,validate

ROOT=Path(__file__).resolve().parent
MANIFEST=ROOT/"SOURCE_ORIGINAL_SHA256_PROVENANCE_MANIFEST.json"
INPUT_SHA="60ef98bbe1d779ef4d79e7d82c9c3c51d2b2c8b14b79be158574d437c058e233"
SOURCE_SHA="3b8ba0b61812aaff6a943fe50b5bfc3364aac2f0b262ba4fba2a89a4c1f586a2"
PREPUBLIC="ed031bd3897573defc4d3ddde1f7970fc5e9747a"
PREPRIVATE="30d2f78bc04d578728f73d2f39556027377c94ab"
RUNS={"43678433690":"AMD EPYC 7763",
      "43678440057":"AMD EPYC 9V45",
      "43678436063":"AMD EPYC 9V74"}

def sha(raw):
    return hashlib.sha256(raw).hexdigest()

def main():
    published=checked_input()
    assert sha((ROOT/"input.json").read_bytes())==INPUT_SHA
    m=json.loads(MANIFEST.read_bytes())
    assert m["input_sha256"]==INPUT_SHA
    assert m["genuine_original_numeric_sha256"]==SOURCE_SHA
    assert m["public_original_runner_precommit"]==PREPUBLIC
    assert m["native_private_preoriginal_forecast_commit"]==PREPRIVATE
    assert m["source_unseen_V12"]=="NOT_GENERATED"
    assert [r["run"] for r in m["runs"]]==list(RUNS)
    first=None
    for run in m["runs"]:
        assert run["cpu"]==RUNS[run["run"]]
        assert run["original_sha256"]==SOURCE_SHA
        rawdata={}
        for key,details in run["archived"].items():
            filename=ROOT/details["path"]
            assert filename.exists(),(run["run"],key)
            packed=filename.read_bytes()
            assert sha(packed)==details["compressed_sha256"]
            raw=gzip.decompress(packed)
            assert sha(raw)==details["uncompressed_sha256"]
            rawdata[key]=raw
        assert sha(rawdata["original"])==SOURCE_SHA
        cpu=rawdata["cpu"]
        assert sha(cpu)==run["original_vendor_cpu_sha256"]
        assert run["cpu"].encode() in cpu
        assert ("Commit="+PREPUBLIC).encode() in cpu
        assert b"mkl" in cpu or b"MKL" in cpu
        original_manifest={}
        for line in rawdata["original_manifest"].decode().strip().splitlines():
            digest,path=line.split(maxsplit=1)
            original_manifest[Path(path).name]=digest
        assert original_manifest["original_gamma_beta_branch_v7_disclosed.json"]==SOURCE_SHA
        assert original_manifest["cpu_and_original_vendor.txt"]==sha(cpu)
        assert original_manifest["input.json"]==INPUT_SHA
        parsed=json.loads(rawdata["original"])
        validate(parsed,published)
        if first is None:first=rawdata["original"]
        assert rawdata["original"]==first,"original different across genuine AMD original hosts"
        print("VALID",run["run"],run["cpu"],"2x original repetitions, byte-identical")
    print("Original source R2026b SHA256",SOURCE_SHA)
    print("All 3 original AMD CPU source archives SHA-VERIFIED; V12 NOT GENERATED")

if __name__=="__main__":
    main()
