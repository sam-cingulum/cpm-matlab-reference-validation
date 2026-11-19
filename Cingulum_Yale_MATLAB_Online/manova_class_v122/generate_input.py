"""Synthetic six-task and underspecified-task MANOVA class calls and fixed 268-node masks."""
from pathlib import Path
import random,struct,json,hashlib
rng=random.Random(1220191);bits=lambda x:struct.pack(">d",x).hex()
rows=[]
for j in range(6):
    side=3+j%2;n=25+3*j;tasks=(2,5,6,7,6,6)[j]
    labels=[i%2 for i in range(n)];X=[]
    for t in range(tasks):
        for d in labels:
            mat=[0.]*(side*side)
            for c in range(side):
                for r in range(c+1,side):
                    v=rng.gauss(.3*d*(1+t%2),1.);mat[r+c*side]=mat[c+r*side]=v
            X.extend(mat)
    # Symmetric adjacency patterns, with connected pixels, ties and isolated edges.
    coords=[[(4,1)],[(7,2),(8,2),(9,2),(20,6)],[(13,3),(14,3),(14,4),(30,25),(31,25),(31,26)],
            [(201,177),(202,177),(203,177),(202,178)],[(266,263),(267,263),(267,264)],[(50,3),(100,2),(200,1)]][j]
    probs=[rng.random()*.65 for _ in range(19+j*9)]+[.0001,.001,.003,0.,.005]
    rows.append(dict(id=f"manova_{j}",shape=[side,side,n,tasks],matrix=list(map(bits,X)),labels=labels,
                     coords=coords,prob=list(map(bits,probs)),seed=1891+j))
p=Path(__file__).with_name("input.json");p.write_text(json.dumps(rows,separators=(",",":"))+"\n")
p.with_suffix(".sha256").write_text(hashlib.sha256(p.read_bytes()).hexdigest()+"  input.json\n")
