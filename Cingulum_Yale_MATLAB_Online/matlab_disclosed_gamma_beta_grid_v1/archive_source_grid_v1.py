#!/usr/bin/env python3
"""Permanently retain unchanged original R2026b disclosed V1 numerical bytes."""
import gzip
import hashlib
import io
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent
ORIGINAL_RUN_COMMIT = "012963ae6efe6ae690ad394ded08f0e22c8a82c9"
INPUT_SHA = "0c7da494a9c70dee799e49de266c3de5d543b323169309e7b57b16938a1f67af"
ORIGINAL_SHA = "e887aac8fb98a748c142247ad8d33babb810e0b2737f49c6f835d6b22faf38f7"
RUNS = (43534195678, 43534693103, 43534696574)
FILES = ("original_disclosed_gamma_beta_grid_v1.json", "cpu_original.txt", "original_manifest.sha256")


def sha(data):
    return hashlib.sha256(data).hexdigest()


def compress(data):
    output = io.BytesIO()
    with gzip.GzipFile(fileobj=output, mode="wb", filename="", compresslevel=9, mtime=0) as out:
        out.write(data)
    return output.getvalue()


def preserve(path, data):
    if path.exists():
        assert path.read_bytes() == data, f"immutable original source differs: {path}"
    else:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(data)


def main():
    assert sha((ROOT / "input.json").read_bytes()) == INPUT_SHA
    manifests = []
    for run in RUNS:
        src = ROOT / f"source_run_{run}"
        dest = ROOT / "source_runs" / str(run)
        hashes = {}
        for name in FILES:
            data = (src / name).read_bytes()
            hashes[name] = sha(data)
            preserve(dest / f"{name}.gz", compress(data))
        assert hashes[FILES[0]] == ORIGINAL_SHA, "original output bytes not identical"
        out = json.loads((src / FILES[0]).read_bytes())
        assert out["classification"] == "ORIGINAL_MATHWORKS_R2026B_SOURCE_DISCLOSED_GAMMA_BETA_GRID_V1"
        assert out["release"] == "2026b" and out["original_unmodified"] is True
        assert out["repetitions"] == 2 and out["gamma_count"] == 423 and out["beta_count"] == 840
        assert len(out["gamma"]) == 846 and len(out["beta"]) == 1680
        cpu = (src / FILES[1]).read_text()
        assert f"Run={run}" in cpu and f"Commit={ORIGINAL_RUN_COMMIT}" in cpu
        assert "AMD EPYC" in cpu and any(v in cpu for v in ("9V45", "9V74", "7763"))
        manifests.append({"run_id": run, "original_sha256": hashes[FILES[0]],
                          "cpu_manifest_sha256": hashes[FILES[1]],
                          "original_manifest_sha256": hashes[FILES[2]],
                          "immutable_archive": f"source_runs/{run}"})
    doc = {
        "classification": "SOURCE_DISCLOSED_ORIGINAL_MATHWORKS_R2026B_NOT_V12_SOURCE_UNSEEN",
        "original_runner_commit": ORIGINAL_RUN_COMMIT,
        "published_input_sha256": INPUT_SHA,
        "original_source_numeric_sha256": ORIGINAL_SHA,
        "genuine_original_repetitions_per_run": 2,
        "original_outputs_identical_across_amd_9v45_and_9v74": True,
        "runs": manifests,
    }
    preserve(ROOT / "ORIGINAL_SHA256_PROVENANCE_MANIFEST.json",
             (json.dumps(doc, indent=2, sort_keys=True) + "\n").encode())
    print(json.dumps(doc, indent=2))


if __name__ == "__main__":
    main()
