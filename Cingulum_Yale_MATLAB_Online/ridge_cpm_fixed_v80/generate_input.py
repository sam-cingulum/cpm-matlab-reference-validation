"""Independent raw 4D synthetic ridgeCPM inputs, including supplied fold labels."""
import hashlib,json,random,struct
from pathlib import Path
rng=random.Random(8087419)
bits=lambda x: struct.pack(">d",x).hex()
cases=[]
for i,(nr,nc,n,nt,k,sym) in enumerate([(3,3,31,1,3,1),(3,3,43,2,4,1),(4,4,57,3,3,1),(4,4,62,2,5,1),
        (3,2,35,1,3,0),(2,4,47,2,4,0),(3,4,79,3,3,0),(5,3,99,2,5,0),(7,7,113,2,4,1),(6,6,71,3,5,0)]):
    y=[rng.gauss(.23,1.) for _ in range(n)]
    A=[];sig=0
    for task in range(nt):
        for subj,v in enumerate(y):
            slab=[0.]*(nr*nc)
            for col in range(nc):
                for row in range(col+1 if sym else 0,nr):
                    active=(row==col+1 and col==0) if sym else (col==0 and row==task%nr)
                    value=rng.gauss(.05*col,1.)+((-1)**task)*1.8*v*active
                    slab[row+col*nr]=value
                    if sym:slab[col+row*nr]=value
            A.extend(slab)
    labels=[s%k+1 for s in range(n)] if i%2 else []
    if labels:rng.shuffle(labels)
    cases.append(dict(id=f"ridge_{i}_{nr}x{nc}x{n}x{nt}",shape=[nr,nc,n,nt],matrix=list(map(bits,A)),outcomes=list(map(bits,y)),threshold=.005,
                      alpha=[1e-9,.375,1.][i%3],lambda_value=[.375,.125,.07][i%3],k=k,seed=rng.randrange(2000000),fold_labels=labels))
p=Path(__file__).with_name("input.json")
p.write_text(json.dumps(cases,separators=(",",":"))+"\n")
p.with_suffix(".sha256").write_text(hashlib.sha256(p.read_bytes()).hexdigest()+"  input.json\n")
