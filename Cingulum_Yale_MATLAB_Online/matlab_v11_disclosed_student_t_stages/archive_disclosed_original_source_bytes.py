#!/usr/bin/env python3
"""Permanently archive source original R2026b V11 *disclosed* stage bytes.

Each original GitHub Actions run is retained separately, even when outputs
match byte-for-byte. Deterministic gzip; no numerical value is modified.
"""
import gzip
import hashlib
import io
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent
RUNS = (43527737601, 43527741572, 43527745106)
KNOWN_SOURCE_SHA256 = "84dbb7581304b38e59930985efb47ae26a150cc0cab0aff4974091311fa342a5"
ORIGINAL_RUNNER_COMMIT = "194cfd6a10759aedd349bf8f27e2a481cf0efa87"
INPUT_SHA256 = "1144418910dc6a81ba3b98f9540fe914ac796d9a9bab25ce75f6c1ef2ace2f53"


def sha(data):
    return hashlib.sha256(data).hexdigest()


def gz(data):
    out = io.BytesIO()
    with gzip.GzipFile(filename="", mode="wb", fileobj=out, compresslevel=9, mtime=0) as file:
        file.write(data)
    return out.getvalue()


def put_immutable(path, data):
    if path.is_file():
        assert path.read_bytes() == data, f"immutable archive unexpectedly differs: {path}"
    else:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(data)


def main():
    manifests = []
    for number in RUNS:
        source = ROOT / f"source_run_{number}"
        target = ROOT / "source_runs" / str(number)
        names = ("original_v11_disclosed_student_t_stages.json",
                 "cpu_and_vendor_fingerprint.txt", "original_sha256_manifest.txt")
        found = {}
        for name in names:
            raw = (source / name).read_bytes()
            found[name] = sha(raw)
            put_immutable(target / (name + ".gz"), gz(raw))
        assert found[names[0]] == KNOWN_SOURCE_SHA256, "genuine R2026b numeric source changed"
        source_doc = json.loads((source / names[0]).read_bytes())
        assert source_doc["classification"] == "ORIGINAL_MATHWORKS_R2026B_V11_DISCLOSED_STUDENT_T_STAGES_ONLY"
        assert source_doc["original_source_unmodified"] is True and source_doc["release"] == "2026b"
        assert source_doc["raw_input_sha256"] == INPUT_SHA256
        assert len(source_doc["rows"]) == 1920
        original_cpu = (source / names[1]).read_text()
        assert f"Original Run={number}" in original_cpu
        assert "AMD EPYC" in original_cpu
        assert "Source Commit=" + ORIGINAL_RUNNER_COMMIT in original_cpu
        manifests.append({"original_action_run_id": number,
                          "original_source_sha256": found[names[0]],
                          "cpu_sha256": found[names[1]],
                          "runner_original_sha256_manifest_sha256": found[names[2]],
                          "archive_folder": "source_runs/" + str(number)})
    evidence = {
        "classification": "SOURCE_DISCLOSED_ONLY_NOT_V12_SOURCE_UNSEEN_CERTIFICATION",
        "original_repository_commit": ORIGINAL_RUNNER_COMMIT,
        "original_raw_input_sha256": INPUT_SHA256,
        "unchanged_mathworks_R2026b": True,
        "original_outputs_byte_identical_across_amd_profiles": True,
        "source_output_sha256": KNOWN_SOURCE_SHA256,
        "genuine_original_runs": manifests,
    }
    put_immutable(ROOT / "SOURCE_ORIGINAL_SHA256_MANIFEST.json",
                  (json.dumps(evidence, sort_keys=True, indent=2) + "\n").encode())
    print(json.dumps(evidence, indent=2))


if __name__ == "__main__":
    main()
