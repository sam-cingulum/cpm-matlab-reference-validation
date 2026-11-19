"""Eight synthetic connectomes spanning both original Yale tolerance branches."""
import hashlib
import json
from pathlib import Path
import random
import struct

rng = random.Random(8186223)
bits = lambda v: struct.pack(">d",v).hex()
cases = []
for index,(n,parcels,k,signals) in enumerate([
    (33,3,3,1),(53,4,4,2),(65,5,3,6),(81,6,5,8),
    (45,25,3,2),(59,26,4,4),(73,25,5,6),(93,27,3,7)
]):
    m = parcels*(parcels-1)//2
    y = [rng.gauss(.25,1.3) for _ in range(n)]
    x = [[rng.gauss(.25,1.) + (v*(-1)**j*(1.+j/8) if j<signals else 0.) for j in range(m)] for v in y]
    cases.append(dict(id=f"n{n}_m{m}",n=n,m=m,parcels=parcels,k=k,seed=rng.randrange(1,2000000),
                      p=.005,grid=[.145,.01875,.625],x=[bits(v) for row in x for v in row],y=list(map(bits,y))))
p = Path(__file__).with_name("input.json")
p.write_text(json.dumps(cases,separators=(",",":"))+"\n")
p.with_suffix(".sha256").write_text(hashlib.sha256(p.read_bytes()).hexdigest()+"  input.json\n")
