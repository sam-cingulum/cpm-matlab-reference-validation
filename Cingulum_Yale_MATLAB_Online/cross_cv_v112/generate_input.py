"""Rebuild the eight regularized training designs selected in the original cross V110."""
from pathlib import Path
import hashlib
import json

root = Path(__file__).resolve().parent
source = (root.parent/"cross_v110/input.json").read_bytes()
assert hashlib.sha256(source).hexdigest()=="055f483545d9bdf8cc65d0744be88809a3abe43a17f89abb6ac2ce2ed898a8c0"
selected = [[0,1,2],[0,1,2,3,4,6,7,8,9,10],[0,1,2,3,4,5,6,7,8],
            [0,1,2,3,4,5,6,9,10,11,12,13,14],[0,1,2,3,4],[0,1,2,3,4,5,6,7,8,9],
            [0,1,2,3,4,5,8,9,10,11,12,13,14,15],[0,1,2,3,4,6,7,8,9,10,11]]
rows = []
for q,indices in zip(json.loads(source),selected,strict=True):
    g=q["train"];side,_,n,tasks=g["shape"];a=g["matrix"];stride=side*side
    symmetric=all(a[r+c*side]==a[c+r*side] for c in range(side) for r in range(c+1,side))
    offsets=[r+c*side for c in range(side) for r in range(c+1 if symmetric else 0, side)]
    ts=[g["task"]-1] if g["task"] else range(tasks)
    columns=[[a[(t*n+i)*stride+o] for i in range(n)] for t in ts for o in offsets]
    rows.append(dict(id=q["id"],n=n,m=len(indices),seed=q["seed"],alpha=q["alpha"],
                     x=[v for j in indices for v in columns[j]],y=g["outcomes"]))
p=root/"input.json"
p.write_text(json.dumps(rows,separators=(",",":"))+"\n")
p.with_suffix(".sha256").write_text(hashlib.sha256(p.read_bytes()).hexdigest()+"  input.json\n")
