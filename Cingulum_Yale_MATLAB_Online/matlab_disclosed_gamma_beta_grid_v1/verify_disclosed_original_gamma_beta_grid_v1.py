#!/usr/bin/env python3
"""Strict old-input SHA, original two-pass repeat and complete-hex verifier."""
import hashlib
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
HEX = re.compile(r"[0-9a-fA-F]{16}\Z")

def sha(raw):
    return hashlib.sha256(raw).hexdigest()

def main():
    src = json.loads((ROOT / "input.json").read_bytes())
    raw = (ROOT / "input.json").read_bytes()
    assert (ROOT / "input.sha256").read_text().strip().split()[0] == sha(raw)
    doc = json.loads(Path(sys.argv[1]).read_bytes())
    assert doc["classification"] == "ORIGINAL_MATHWORKS_R2026B_SOURCE_DISCLOSED_GAMMA_BETA_GRID_V1"
    assert doc["input_schema"] == src["schema"]
    assert doc["release"] == "2026b" and doc["original_unmodified"] is True
    assert doc["mkl_cbwr"] == "COMPATIBLE" and doc["max_num_comp_threads"] == 1
    assert doc["gamma_count"] == len(src["gamma"]) and doc["beta_count"] == len(src["beta"])
    assert doc["repetitions"] == 2
    for kind in ("gamma", "beta"):
        n = len(src[kind])
        rows = doc[kind]
        assert len(rows) == n * 2
        for i in range(n):
            x, y = dict(rows[i]), dict(rows[n+i])
            assert x.pop("rep") == 1 and y.pop("rep") == 2
            assert x == y, (kind, i, "original nonrepeatable")
            assert x["id"] == src[kind][i]["id"], (kind, i)
            for k, v in x.items():
                if k.endswith("_hex"):
                    assert isinstance(v,str) and HEX.fullmatch(v), (kind,i,k)
    print("ORIGINAL R2026b disclosed gamma",len(src["gamma"]),"beta",len(src["beta"]),
          "two-pass repeat and all hex fields exactly verified")

if __name__ == "__main__":
    main()
