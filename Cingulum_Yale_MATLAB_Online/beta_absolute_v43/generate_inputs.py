"""Fixed developmental V43 finite interior beta cohort, independent of original results."""
import hashlib
import json
import math
import random
import struct
from pathlib import Path

def main():
    rng=random.Random(0x43B37A)
    cases=[]
    for i in range(144):
        a,b=(2**rng.uniform(-6,8.2) for _ in range(2))
        if i%4==0:
            a=rng.randrange(1,161)*0.5
            b=0.5
        elif i%4==1:
            b=a
        mean=a/(a+b)
        switch=(a+1)/(a+b+2)
        xs=[rng.random(), 2**rng.uniform(-600,-8), 1-2**rng.uniform(-51,-8)]
        for c in (mean,switch):
            xs.extend([math.nextafter(c,0),c,math.nextafter(c,1)])
        for x in sorted(set(xs)):
            h=lambda v:struct.pack(">d",v).hex()
            cases.append(dict(id=f"v43_{len(cases):04d}",a_hex=h(a),b_hex=h(b),x_hex=h(x)))
    raw=(json.dumps(dict(beta=cases,original_MATLAB_numeric_data_supplied=False,
                        source_unseen_V12="NOT_GENERATED"),indent=2)+"\n").encode()
    folder=Path(__file__).resolve().parent
    (folder/"input.json").write_bytes(raw)
    (folder/"input.sha256").write_text(hashlib.sha256(raw).hexdigest()+"  input.json\n")
    print(len(cases))

if __name__=="__main__":
    main()
