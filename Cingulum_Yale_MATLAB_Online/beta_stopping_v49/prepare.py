"""Apply the pinned V28 measurement to a new input-only cohort in a scratch directory."""
import hashlib
import json
import re
import struct
import sys
from pathlib import Path

here = Path(__file__).resolve().parent
prior = here.parent / "matlab_r2026b_special_function_native_metadata_v2"
dst = Path(sys.argv[1])
dst.mkdir(exist_ok=True)
data = (here / "input.json").read_bytes()
rows = json.loads(data)["cases"]
sha = hashlib.sha256(data).hexdigest()
name = "beta_lentz_iteration_v49_raw_inputs.json"
(dst / name).write_bytes(data)
(dst / "beta_lentz_iteration_v49_raw_inputs.sha256").write_text(f"{sha}  {name}\n")
coeff = lambda h: struct.unpack(">d",bytes.fromhex(h))[0].hex()
cases = [f"        {{{coeff(r['x_hex'])}, {coeff(r['a_hex'])}, {coeff(r['b_hex'])}, {r['tail']}}}," for r in rows]
s = (prior / "trace_beta_lentz_iteration_v28.cpp").read_text()
s, n = re.subn(r"(?<=const std::array<BetaCase,80> rows\{\{\n).*?(?=    \}\};)", "\n".join(cases)+"\n", s, flags=re.S)
assert n == 1 and len(cases) == 80
(dst / "trace_beta_lentz_iteration_v49.cpp").write_text(s)
s = (prior / "trace_beta_lentz_iteration_v28.gdb.py").read_text()
s, n = re.subn(r"^LABELS=.*$", "LABELS="+repr([r["label"] for r in rows]), s, flags=re.M)
assert n == 1
s = s.replace("V28", "V49").replace("c6cec58300d8801d6216f653202fdb7e91e63ed7794f39f301f00e7d029d6825",sha)
s = s.replace("24 preregistered shape-vs-x points", "40 preregistered shape-vs-x points")
(dst / "trace_beta_lentz_iteration_v49.gdb.py").write_text(s)
