import json,struct,random
from pathlib import Path
def design(i):
    r=random.Random(11112000+i)
    n=30+i%12;m=31+i%17
    z=[r.gauss(0,1) for _ in range(n)]
    cols=[[r.gauss(.025*j,.65+j/9)+1.1*v for v in z] for j in range(m)]
    y=[r.gauss(.2,.45)+sum(col[k]*(-1)**j/(1+j) for j,col in enumerate(cols)) for k in range(n)]
    bits=lambda v:struct.pack('>d',v).hex()
    return dict(id=f"support_{i}",n=n,m=m,alpha=(.23,.371,.65,.89)[i%4],x=[bits(v) for c in cols for v in c],y=list(map(bits,y)))

# Eight designs distinguish two frozen stopping forecasts. Four unselected controls.
if __name__ == "__main__":
    import hashlib
    rows = [design(i) for i in [11,114,130,504,574,922,1034,1537,1609,1610,1611,1612]]
    path = Path(__file__).with_name("input.json")
    path.write_text(json.dumps(rows,separators=(",",":"))+"\n")
    path.with_suffix(".sha256").write_text(hashlib.sha256(path.read_bytes()).hexdigest()+"  input.json\n")
