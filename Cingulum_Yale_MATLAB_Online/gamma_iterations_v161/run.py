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
symbols=subprocess.check_output(["nm","-D","-S","--defined-only",lib],text=True)
entry, = [s.split() for s in symbols.splitlines() if s.split()[-1]==symbol]
start,size=int(entry[0],16),int(entry[1],16)
assembly=subprocess.check_output(["objdump","-d","--no-show-raw-insn",
    "--start-address="+str(start),"--stop-address="+str(start+size),lib],text=True)
import re
offsets=[]
for address,target in re.findall(r"^\s*([0-9a-f]+):\s+j\w+\s+([0-9a-f]+)\b",assembly,re.M):
    address,target=int(address,16),int(target,16)
    if start<=target<address<start+size:
        offsets.append(address-start)
assert offsets
Path("branches.json").write_text(json.dumps(offsets))
cmd = ["/tmp/cpm-gamma-v161", lib, symbol]
def run():
    plain = subprocess.check_output(cmd, input="\n".join(inputs)+"\n", text=True)
    subprocess.run(["gdb", "-q", "-nx", "--batch", "-x", "count.py", "--args", *cmd], check=True)
    assert plain == Path("traced.txt").read_text()
    counts = json.loads(Path("counts.json").read_bytes())
    rows = []
    for line, calls in zip(plain.splitlines(), counts, strict=True):
        x, shape, mode, value = line.split()
        if mode == "2":
            assert not calls
        rows.append(dict(x=x, shape=shape, mode=int(mode), value=value, calls=calls))
    assert [(r["x"],r["shape"]) for r in rows] == [tuple(x.split()) for x in inputs for _ in range(3)]
    return rows
a,b=run(),run()
assert [(r["x"],r["shape"],r["mode"],r["value"]) for r in a] == [(r["x"],r["shape"],r["mode"],r["value"]) for r in b]
assert [[v["offset"] for v in r["calls"]] for r in a] == [[v["offset"] for v in r["calls"]] for r in b]
Path("observations.json").write_text(json.dumps(dict(run=os.environ["GITHUB_RUN_ID"],
    commit=os.environ["GITHUB_SHA"],input_sha256=hashlib.sha256(Path("probes.txt").read_bytes()).hexdigest(),
    source_unseen=False, loop_offsets=offsets, repetitions=[a,b]),sort_keys=True,separators=(",",":"))+"\n")
