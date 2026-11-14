#!/usr/bin/env python3
"""Synthetic structural negative-control test, NOT an original MATLAB oracle."""
import copy
import unittest

from verify_original_gamma_beta_switch_microprobe_v2 import (
    CLASSIFICATION, REQUIRED_INPUT, REQUIRED_OUTPUT,
    checked_input, validate,
)


def fake_original_contract(src):
    """Create a TEST-ONLY schema fixture, not authentic original numbers."""
    out = dict(
        classification=CLASSIFICATION,
        source_unseen_V12="NOT_GENERATED",
        input_schema=src["schema"],
        original_unmodified=True,
        release="2026b",
        matlab_version="SYNTHETIC_STRUCTURAL_TEST_NOT_MATLAB",
        computer="SYNTHETIC",
        mkl_cbwr="COMPATIBLE",
        max_num_comp_threads=1,
        repetitions=2,
    )
    for kind in REQUIRED_OUTPUT:
        n = src[kind + "_count"]
        out[kind + "_count"] = n
        rows = []
        for rep in (1, 2):
            for raw in src[kind]:
                row = {key: "0000000000000000"
                       for key in REQUIRED_OUTPUT[kind] - REQUIRED_INPUT[kind] - {"rep"}}
                row.update(raw)
                row["rep"] = rep
                rows.append(row)
        out[kind] = rows
    return out


class StructuralVerifierTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.input = checked_input()

    def test_complete_synthetic_schema_passes_as_schema_only(self):
        validate(fake_original_contract(self.input), self.input)

    def test_changed_single_original_bit_is_rejected(self):
        x = fake_original_contract(self.input)
        x["gamma"][0]["gammaln_hex"] = "0000000000000001"
        with self.assertRaises(AssertionError):
            validate(x, self.input)

    def test_mismatched_input_sha_or_missing_field_rejected(self):
        x = fake_original_contract(self.input)
        del x["beta"][0]["upper_hex"]
        with self.assertRaises(AssertionError):
            validate(x, self.input)
        x = fake_original_contract(self.input)
        x["student"][0]["t_hex"] = "3ff0000000000000"
        with self.assertRaises(AssertionError):
            validate(x, self.input)


if __name__ == "__main__":
    unittest.main()
