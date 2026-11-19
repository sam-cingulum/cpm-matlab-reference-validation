"""Cross penalty mode, fold source and response ties over fresh synthetic task matrices."""
import hashlib
import json
import random
import struct
from pathlib import Path

rng = random.Random(861997)
bits = lambda v: struct.pack(">d", v).hex()
cases = []
for mode, penalty in [('fixed', .125), ('supplied', [.35, .0625, 1., .14]), ('auto', [])]:
    for design in range(8):
        nr, nc, nt = [(4,4,1),(5,5,2),(7,3,1),(4,4,2),
                      (3,5,2),(14,11,2),(6,6,2),(5,6,1)][design]
        n = (61,73,85,97,103,111,119,131)[design]
        k = 3 + design % 2
        symmetric = nr == nc
        coordinates = [(i,j) for j in range(nc) for i in range(j+1 if symmetric else 0,nr)]
        active = (1,3,5,6,6,7,8,16)[design]
        y = [rng.gauss(.2,1.) for _ in range(n)]
        if design in (1,2,5,6):
            y = [round(v*3)/3 for v in y]
        matrix = []
        for task in range(nt):
            for outcome in y:
                slab = [0.]*(nr*nc)
                for edge,(i,j) in enumerate(coordinates):
                    signal = (-1)**(edge+task)*1.55*outcome if edge < active else 0.
                    value = rng.gauss(.04*j,1.) + signal
                    slab[i+j*nr] = value
                    if symmetric:
                        slab[j+i*nr] = value
                matrix.extend(slab)
        supplied = design in (1,3,4,6)
        labels = [i%k+1 for i in range(n)] if supplied else []
        rng.shuffle(labels)
        cases.append(dict(id=f'{mode}_{design}',shape=[nr,nc,n,nt],matrix=list(map(bits,matrix)),
                          outcomes=list(map(bits,y)),threshold=.0001,alpha=[.375,1e-9,1.][design%3],
                          lambda_value=penalty,k=k,seed=rng.randrange(1000000),fold_labels=labels))
p = Path(__file__).with_name('input.json')
p.write_text(json.dumps(cases,separators=(',',':'))+'\n')
p.with_suffix('.sha256').write_text(hashlib.sha256(p.read_bytes()).hexdigest()+'  input.json\n')
