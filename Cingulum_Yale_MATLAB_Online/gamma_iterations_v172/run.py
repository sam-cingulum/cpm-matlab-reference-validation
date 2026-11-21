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
# Inspect control-flow metadata locally. The artifact contains numerical states
# and relative offsets, while original instruction bytes stay on the licensed host.
assembly=subprocess.check_output(["objdump","-d","--section=.text","--no-show-raw-insn",lib],text=True)
import re
instructions={}
order=[]
for line in assembly.splitlines():
    m=re.match(r"^\s*([0-9a-f]+):\s+(\S+)\s*(.*)$",line)
    if not m:
        continue
    address=int(m[1],16)
    target=re.match(r"([0-9a-f]+)\b",m[3])
    instructions[address]=(m[2],int(target[1],16) if target else None)
    order.append(address)
following=dict(zip(order,order[1:]))
seen=set()
pending=[start]
offsets=[]
while pending:
    address=pending.pop()
    if address in seen or address not in instructions:
        continue
    seen.add(address)
    assert len(seen)<250000
    mnemonic,target=instructions[address]
    if mnemonic.startswith("j") and target is not None and target < address and target in instructions:
        offsets.append(address-start)
    if mnemonic.startswith(("j","call")) and target in instructions:
        pending.append(target)
    if not mnemonic.startswith(("ret","jmp","ud2")) and address in following:
        pending.append(following[address])
offsets=sorted(set(offsets))
assert len(offsets)>1
Path("branches.json").write_text(json.dumps(offsets))
cmd = ["/tmp/cpm-gamma-v172", lib, symbol]
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
