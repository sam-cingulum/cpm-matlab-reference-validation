"""Adversarial archived MathWorks R2026b retrospective evidence integrity tests."""
import pathlib
import shutil
import sys
import tempfile
import unittest
sys.path.insert(0,str(pathlib.Path(__file__).resolve().parent))
import verify_archived_evidence as verification

class ArchivedNativeQrTest(unittest.TestCase):
 def test_genuine_original_48_cases_consistent(self):
  v=verification.check()
  self.assertEqual(v["artifacts_sha256_verified"],5)
  self.assertEqual(v["native_transport_identical"],48)
  self.assertEqual(v["exact_MATLAB_cross_AMD_R_entries"],192)
  self.assertEqual(v["native_R_exact_entries"],123)
  self.assertFalse(v["source_unseen"])
 def test_one_bit_tamper_fails_closed(self):
  with tempfile.TemporaryDirectory() as temp:
   dst=pathlib.Path(temp)
   for file in verification.SHA:shutil.copyfile(verification.ART/file,dst/file)
   p=dst/"native_r_hex_43181373473.tsv"
   data=p.read_bytes()
   p.write_bytes(bytes([data[0]^1])+data[1:])
   with self.assertRaisesRegex(AssertionError,"AUTHENTIC_ARTIFACT_SHA256_MISMATCH"):
    verification.check(dst)

if __name__=="__main__":unittest.main()
