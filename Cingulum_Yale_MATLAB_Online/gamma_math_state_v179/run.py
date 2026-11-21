"""Genuine-original gamma arithmetic state experiment, licensed runner only.

Uses disassembly privately solely to select numeric arithmetic checkpoints.
Emits only relative offsets, eight IEEE-binary64 numeric registers and scalar
input/output. No vendor instruction mnemonic/bytes are exported or copied.
"""
from pathlib import Path
import hashlib
import json
import os
import re
import subprocess
import sys

inputs=Path("probes.txt").read_text().splitlines()
lib=sys.argv[1]
names=subprocess.check_output(["nm","-D","--defined-only",lib],text=True)
symbol,=[s.split()[-1] for s in names.splitlines()
         if s.split()[-1].startswith("_ZN8mathspec8gammaincEdd")]
entry,=[s.split() for s in subprocess.check_output(
    ["nm","-D","-S","--defined-only",lib],text=True).splitlines()
    if s.split()[-1]==symbol]
start=int(entry[0],16)

# Parse floating-point arithmetic sites only in the bounded surrounding
# numerical function region. Licensed disassembly is ephemeral.
assembly=subprocess.check_output(
    ["objdump","-d","--section=.text","--no-show-raw-insn",lib],
    text=True)
sites=set()
for line in assembly.splitlines():
    m=re.match(r"^\s*([0-9a-f]+):\s+(\S+)\s*(.*)$",line)
    if not m:
        continue
    address=int(m[1],16)
    relative=address-start
    if not -5600<=relative<=120:
        continue
    mnemonic=m[2].lstrip("v")
    if mnemonic.startswith((
        "mulsd","divsd","addsd","subsd","sqrtsd","fmadd","fnmadd",
        "fmsub","cvtsi2sd","maxsd","minsd","roundsd")):
        sites.add(relative)
assert 50<len(sites)<2500, len(sites)
Path("math_sites.json").write_text(json.dumps(sorted(sites)))

cmd=["/tmp/cpm-gamma-v179",lib,symbol]

def run():
    plain=subprocess.check_output(cmd,input="\n".join(inputs)+"\n",text=True)
    subprocess.run(["gdb","-q","-nx","--batch","-x","trace.py","--args",*cmd],
                   check=True)
    assert plain==Path("traced.txt").read_text()
    counts=json.loads(Path("math_counts.json").read_bytes())
    assert counts["site_count"]==len(sites)
    rows=[]
    for line,events in zip(plain.splitlines(),counts["rows"],strict=True):
        x,shape,mode,value=line.split()
        if mode=="2":
            assert not events
        assert len(events)<10000
        rows.append({"x":x,"shape":shape,"mode":int(mode),
                     "value":value,"events":events})
    assert len(rows)==3*len(inputs)
    assert [(q["x"],q["shape"]) for q in rows]==[
        tuple(x.split()) for x in inputs for _ in range(3)]
    return rows

first,second=run(),run()
assert [(r["x"],r["shape"],r["mode"],r["value"],
         [e["offset"] for e in r["events"]]) for r in first]==[
        (r["x"],r["shape"],r["mode"],r["value"],
         [e["offset"] for e in r["events"]]) for r in second]

Path("observations.json").write_text(json.dumps({
    "classification":"licensed original-only source-disclosed numerical register evidence",
    "source_unseen":False,
    "run":os.environ["GITHUB_RUN_ID"],
    "commit":os.environ["GITHUB_SHA"],
    "input_sha256":hashlib.sha256(Path("probes.txt").read_bytes()).hexdigest(),
    "arithmetic_site_count":len(sites),
    "repetitions":[first,second],
},sort_keys=True,separators=(",",":"))+"\n")
