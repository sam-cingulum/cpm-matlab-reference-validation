"""Match public MATLAB scalar gamma probes to the installed original ABI and host math."""
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys

folder = Path(__file__).resolve().parent
inputs = (folder.parent/"gamma_shape_one_v127/input.json").read_bytes()
assert hashlib.sha256(inputs).hexdigest() == "271d8cc97328d34359bf491cf6d67bfa67f012fa0714f266c25e47d290f38da0"
xs = json.loads(inputs)
symbols = subprocess.check_output(["nm","-D","--defined-only",sys.argv[1]],text=True)
sym, = [s.split()[-1] for s in symbols.splitlines() if s.split()[-1].startswith("_ZN8mathspec8gammaincEdd")]
stdin = "\n".join(xs)+"\n"
def run():
    buf=subprocess.check_output(["/tmp/cpm-gamma-v130",sys.argv[1],sym],text=True,input=stdin)
    rows=[line.split() for line in buf.splitlines()]
    assert [r[0] for r in rows]==xs and all(len(r)==7 and all(len(v)==16 for v in r) for r in rows)
    return rows
a,b=run(),run()
assert a==b
(folder/"abi.json").write_text(json.dumps(dict(commit=os.environ["GITHUB_SHA"],run=os.environ["GITHUB_RUN_ID"],
                    input_sha256=hashlib.sha256(inputs).hexdigest(),repetitions=[a,b]),separators=(",",":"))+"\n")
