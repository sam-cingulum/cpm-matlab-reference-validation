"""Synthetic, shuffled family structures and scalar RNG seeds."""
from pathlib import Path
import hashlib,json,random
rng=random.Random(2026111963)
rows=[]
for i in range(90):
    n=(17,29,48,61,95,129,257,513,1025)[i%9]
    k=(3,5,7,10,11)[i//9%5]; mode=i%6
    if mode==0:k=10
    if mode==1:k=1
    if mode==2:
        groups=max(1,k-1)
    else:
        groups=rng.randrange(max(k,10),n)
    family=list(range(groups))+[rng.randrange(groups) for _ in range(n-groups)]
    if mode==3:family=list(range(n))
    rng.shuffle(family)
    seed=213 if mode in (0,4) else rng.randrange(2**32)
    rows.append(dict(id=f"v63_{i}_n{n}",family=[3*f-21 for f in family],k=k,seed=seed,
        arity=1 if mode==0 else 2 if mode==4 else 3))
p=Path(__file__).with_name('input.json');p.write_text(json.dumps(rows,separators=(',',':'))+'\n')
p.with_name('input.sha256').write_text(hashlib.sha256(p.read_bytes()).hexdigest()+'  input.json\n')
