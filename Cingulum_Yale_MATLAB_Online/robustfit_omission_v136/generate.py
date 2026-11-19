"""Independent missing-observation patterns through the supported raw row count."""
import hashlib,json,random,struct
from pathlib import Path
rng=random.Random(136701);pack=lambda x:struct.pack(">d",x).hex()
rows=[]
for n in (12,17,26,37,68,94,128,129,130,190,254,255,256,257,258,259,320,511,512,513,767,1025):
    for j in range(4):
        x=[rng.uniform(-1.5,1.75)+(1.625 if j%2 else 0.) for _ in range(n)]
        y=[rng.uniform(-.875,.875)+.3*z for z in x]
        if j==3:
            for k in range(0,n,21):y[k]+=3.25
        xx,yy=list(map(pack,x)),list(map(pack,y))
        flags=[i for i in range(n) if rng.random()<(0.,.07,.16,.24)[j]][:n-9]
        for k,i in enumerate(flags):
            nan=("fff8000000005241","7ff800000000007b","7ff8000000000000")[k%3]
            if k%3!=1:xx[i]=nan
            if k%3!=0:yy[i]=nan
        rows.append(dict(id=f"omission_{n}_{j}",n=n,x_hex=xx,y_hex=yy))
p=Path(__file__).with_name("input.json");buf=(json.dumps(dict(cases=rows),separators=(",",":"))+"\n").encode();p.write_bytes(buf);p.with_suffix(".sha256").write_text(hashlib.sha256(buf).hexdigest()+"  input.json\n")
