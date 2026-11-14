#!/usr/bin/env python3
"""Independent SHA, input and original two-AMD-run replay for disclosed V2.

Only verifies original MATLAB source provenance and repeatability.
Does NOT imply native Rust parity or any V12 source-unseen certificate.
"""
from __future__ import annotations

import gzip
import hashlib
import json
from pathlib import Path

from verify_original_gamma_beta_switch_microprobe_v2 import checked_input, validate

ROOT=Path(__file__).resolve().parent
MANIFEST=ROOT/"SOURCE_ORIGINAL_SHA256_PROVENANCE_MANIFEST.json"


def sha(v:bytes)->str:
    return hashlib.sha256(v).hexdigest()


def read_gzip(path:Path)->bytes:
    return gzip.decompress(path.read_bytes())


def main()->None:
    source=checked_input()
    m=json.loads(MANIFEST.read_bytes())
    assert m["classification"]=="PERMANENT_ARCHIVE_GENUINE_ORIGINAL_R2026B_SOURCE_DISCLOSED_SWITCH_V2_TWO_AMD_HOSTS"
    assert m["source_unseen_V12"]=="NOT_RUN"
    assert m["original_source_input_sha256"]==(ROOT/"input.sha256").read_text().split()[0]
    assert m["original_source_head"]=="2e329bd5038ace9d99d5668c3811fad89941aadd"
    assert m["genuine_original_numeric_sha256"]=="e0f056aa297f8c9d26232e879b69f13dbf8dcd6a2e4d6f68e91ea8766a1aba33"
    runs=m["successful_original_runs"]
    assert set(runs)=={"43541967648","43541973927"}
    data=[]
    for run,record in sorted(runs.items()):
        folder=ROOT/"source_runs"/run
        original_file=folder/"original_gamma_beta_switch_microprobe_v2.json.gz"
        cpu_file=folder/"cpu_and_original_vendor.txt.gz"
        original_sha_file=folder/"original_sha256_manifest.txt.gz"
        assert sha(original_file.read_bytes())==record["original_gzip_sha256"]
        assert sha(cpu_file.read_bytes())==record["cpu_gzip_sha256"]
        original=read_gzip(original_file)
        cpu=read_gzip(cpu_file)
        manifest=read_gzip(original_sha_file).decode()
        assert sha(original)==record["original_uncompressed_sha256"]==m["genuine_original_numeric_sha256"]
        assert sha(cpu)==record["cpu_uncompressed_sha256"]
        assert record["cpu_model"] in cpu.decode()
        assert f"Run={run}" in cpu.decode()
        assert f"Commit={record['public_source_head']}" in cpu.decode()
        assert record["original_uncompressed_sha256"] in manifest
        assert m["original_source_input_sha256"] in manifest
        doc=json.loads(original)
        validate(doc,source)
        data.append(original)
        print(f"ORIGINAL R2026b SHA replay PASS {run}: {record['cpu_model']}")
    assert data[0]==data[1], "different original MATLAB numerical bytes across supported CPUs"
    changed=json.loads(data[0])
    changed["gamma"][0]["gammaln_hex"]=f"{int(changed['gamma'][0]['gammaln_hex'],16)^1:016x}"
    try:
        validate(changed,source)
    except AssertionError:
        pass
    else:
        raise AssertionError("one-bit corrupted source accepted")
    print("SHA-VERIFIED ORIGINAL two-AMD-host source-disclosed numerical bytes exact across both runs")
    print("original SHA256",m["genuine_original_numeric_sha256"])
    print("source-unseen V12 NOT RUN; independent native p parity NOT CLAIMED")


if __name__=="__main__":
    main()
