"""Run original-only gamma controls twice, with and without system-math counters."""
from pathlib import Path
import hashlib
import json
import os
import subprocess
import sys

inputs = Path("probes.txt").read_text().splitlines()
lib = sys.argv[1]
names = subprocess.check_output(["nm", "-D", "--defined-only", lib], text=True)
symbol, = [s.split()[-1] for s in names.splitlines() if s.split()[-1].startswith("_ZN8mathspec8gammaincEdd")]
cmd = ["/tmp/cpm-gamma-v159", lib, symbol]
def run():
    plain = subprocess.check_output(cmd, input="\n".join(inputs)+"\n", text=True)
    subprocess.run(["gdb", "-q", "-nx", "--batch", "-x", "count.py", "--args", *cmd], check=True)
    assert plain == Path("traced.txt").read_text()
    counts = json.loads(Path("counts.json").read_bytes())
    rows = []
    for line, calls in zip(plain.splitlines(), counts, strict=True):
        x, shape, mode, value = line.split()
        if mode == "2":
            assert sum(c["function"]=="log" for c in calls) == sum(c["function"]=="exp" for c in calls) == 1
        rows.append(dict(x=x, shape=shape, mode=int(mode), value=value, calls=calls))
    assert [(r["x"],r["shape"]) for r in rows] == [tuple(x.split()) for x in inputs for _ in range(3)]
    return rows
a,b=run(),run()
assert a==b
Path("observations.json").write_text(json.dumps(dict(run=os.environ["GITHUB_RUN_ID"],
    commit=os.environ["GITHUB_SHA"],input_sha256=hashlib.sha256(Path("probes.txt").read_bytes()).hexdigest(),
    repetitions=[a,b]),sort_keys=True,separators=(",",":"))+"\n")
