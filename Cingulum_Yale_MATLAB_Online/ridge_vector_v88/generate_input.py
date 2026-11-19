"""Fresh family-fold vector ridge inputs, including unused vector pages and omitted subjects."""
import hashlib
import json
from pathlib import Path
import random
import struct

rng = random.Random(8801392026)
def bits(v):
    return struct.pack(">d", v).hex()

cases = []
for mode, penalty in (("fixed", .25), ("supplied", [.3, 1., .04, .125]), ("auto", [])):
    for layout, nr, nt, p, nv, symmetric in (
        ("vector", 0, 1, 7, 1, False),
        ("matrix", 4, 2, 0, 1, True),
        ("mixed", 3, 1, 3, 2, False),
        ("mixed_symmetric", 4, 2, 3, 1, True),
    ):
        n = [59, 67, 79, 89][len(cases) % 4]
        k = 3 if n < 70 else 4
        y = [rng.gauss(.25, 1.) for _ in range(n)]
        if layout == "mixed_symmetric":
            y = [round(v * 4) / 4 for v in y]
        family = list(range(n))
        if layout in ("matrix", "mixed_symmetric"):
            for i in range(1, n, 3):
                family[i] = family[i-1]
        rng.shuffle(family)
        matrix = []
        for t in range(nt):
            for outcome in y:
                slab = [0.] * (nr*nr)
                for j in range(nr):
                    for i in range(j+1 if symmetric else 0, nr):
                        signal = (-1)**(t+i) * 1.8 * outcome if j == 0 else 0.
                        v = rng.gauss(.01*i, 1.) + signal
                        slab[i+j*nr] = v
                        if symmetric:
                            slab[j+i*nr] = v
                matrix.extend(slab)
        vectors = []
        for page in range(nv):
            for outcome in y:
                for j in range(p):
                    signal = (1.8 if page == 0 else -9.) * outcome if j < 2 else 0.
                    vectors.append(rng.gauss(.02*j, 1.) + signal)
        cases.append(dict(id=f"{mode}_{layout}",shape=[nr,nr,n,nt],matrix=list(map(bits,matrix)),
                          vector_shape=[p,n,nv],vectors=list(map(bits,vectors)),family_ids=family,
                          outcomes=list(map(bits,y)),threshold=.001,alpha=[.375,1e-9,1.][len(cases)%3],
                          lambda_value=penalty,k=k,seed=rng.randrange(1000000),fold_labels=[]))
p = Path(__file__).with_name("input.json")
p.write_text(json.dumps(cases, separators=(",", ":")) + "\n")
p.with_suffix(".sha256").write_text(hashlib.sha256(p.read_bytes()).hexdigest() + "  input.json\n")
