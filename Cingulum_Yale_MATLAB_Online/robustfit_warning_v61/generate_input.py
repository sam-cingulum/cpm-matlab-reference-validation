"""A warning-boundary cohort and an independently seeded impulse/outlier cohort."""
from pathlib import Path
import hashlib
import json
import random
import struct

ROOT = Path(__file__).parent
seed = 202611196101
rng = random.Random(seed)
base = (ROOT.parent / "robustfit_expanded_v59/input.json").read_bytes()
assert hashlib.sha256(base).hexdigest() == "0ba985915f43dc9f19176040451570e820feeccd3692af7c2491e6c649ffdecb"
center = next(r for r in json.loads(base)["cases"] if r["scenario"] == "impulse" and r["replicate"] == 17 and r["n"] == 20)
def pack(x):
    return struct.pack(">d",x).hex()
def num(s):
    return struct.unpack(">d", bytes.fromhex(s))[0]
cases=[]
for i in range(480):
    if i < 240:
        # Perturb a single outcome on a known final-update boundary, with both signs.
        n=20
        x=list(map(num,center["x_hex"]))
        y=list(map(num,center["y_hex"]))
        y[i%n]+=(-1 if i//n%2 else 1)*(1+rng.random())*2**(-25+3*(i//(2*n)))
        scenario="boundary_neighborhood"
    else:
        n=(15,16,20,24,30,38,50,64)[i%8]
        x=[rng.gauss(0,.08)+(12. if j==n//3 else -6. if j==n//2 else 0.) for j in range(n)]
        y=[.7+v*.25+rng.gauss(0,.26) for v in x]
        y[n//2]+=rng.uniform(-1.2,1.2)
        scenario="independent_impulse"
    cases.append(dict(id=f"v61_{scenario}_{i}_n{n}",x_hex=list(map(pack,x)),y_hex=list(map(pack,y)),n=n))
assert len({tuple(c["y_hex"]) for c in cases})==480
out=ROOT/"input.json"
out.write_text(json.dumps(dict(seed=seed,cases=cases),separators=(",",":"),sort_keys=True)+"\n")
(ROOT/"input.sha256").write_text(hashlib.sha256(out.read_bytes()).hexdigest()+"  input.json\n")
