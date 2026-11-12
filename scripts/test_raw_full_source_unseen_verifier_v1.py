"""Adversarial tests: require binary64 ALL arrays, fields, source provenance and hashes."""
import copy
import json
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parent))
import verify_raw_full_source_unseen_v1 as v


class ProspectiveVerifierNegativeTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.manifest, cls.data = v.initial()

    @staticmethod
    def fabricated_result():
        cases = []
        for c in v.read(v.DIR / "input.json")["cases"]:
            f = {k: ["0000000000000000"] * (
                c["n"] if k in ("h", "w") else 4 if k == "R" else 1
            ) for k in v.GATES}
            cases.append({"id": c["id"], "n": c["n"], "fields": f})
        return {"experiment_id": v.EXPERIMENT, "release": "2026b",
                "stage": "A_independent_clone_only",
                "input_sha256": v.sha(v.DIR / "input.json"),
                "records": cases}

    def test_all_48_and_12_fields_are_structurally_valid(self):
        f = self.fabricated_result()
        v.check_records(f, self.data, "A_independent_clone_only")
        result = v.exact_comparison(f, copy.deepcopy(f), self.data)
        self.assertTrue(result["all_12_fields_exact_48_of_48"])

    def test_one_ulp_bit_flip_rejected(self):
        f = self.fabricated_result()
        s = copy.deepcopy(f)
        s["records"][47]["fields"]["w"][-1] = "0000000000000001"
        result = v.exact_comparison(f, s, self.data)
        self.assertFalse(result["all_12_fields_exact_48_of_48"])
        self.assertEqual(result["exact_counts"]["w"], 47)
        self.assertEqual(result["mismatches"][0]["case_id"], self.data["cases"][-1]["id"])

    def test_truncation_missing_case_rejected(self):
        f = self.fabricated_result()
        f["records"].pop()
        with self.assertRaises(AssertionError):
            v.check_records(f, self.data, "A_independent_clone_only")

    def test_missing_critical_field_rejected(self):
        f = self.fabricated_result()
        del f["records"][0]["fields"]["ols_s"]
        with self.assertRaises(AssertionError):
            v.check_records(f, self.data, "A_independent_clone_only")

    def test_reordered_cases_rejected(self):
        f = self.fabricated_result()
        f["records"][0], f["records"][1] = f["records"][1], f["records"][0]
        with self.assertRaises(AssertionError):
            v.check_records(f, self.data, "A_independent_clone_only")

    def test_wrong_hex_element_count_rejected(self):
        f = self.fabricated_result()
        f["records"][0]["fields"]["R"] = ["0000000000000000"] * 3
        with self.assertRaises(AssertionError):
            v.check_records(f, self.data, "A_independent_clone_only")

    def test_input_sha256_mutation_rejected(self):
        old_dir = v.DIR
        with tempfile.TemporaryDirectory() as td:
            v.DIR = Path(td)
            try:
                (v.DIR / "manifest.json").write_bytes((old_dir / "manifest.json").read_bytes())
                data = copy.deepcopy(self.data)
                data["cases"][0]["y"][0] += 0.125
                (v.DIR / "input.json").write_text(json.dumps(data))
                with self.assertRaisesRegex(AssertionError, "INPUT_SHA256_MISMATCH"):
                    v.initial()
            finally:
                v.DIR = old_dir

    def test_unpinned_numeric_profile_rejected(self):
        p = {"release": "2026b", "matlab_version": "MATLAB R2026b",
             "max_num_comp_threads": 2, "mkl_cbwr": "AUTO",
             "mkl_num_threads": "2", "omp_num_threads": "2",
             "architecture": "glnxa64", "cpu_model": "CPU",
             "github_sha": "f" * 40, "github_run_id": "1"}
        with self.assertRaises(AssertionError):
            v.check_profile(p)


if __name__ == "__main__":
    unittest.main()
