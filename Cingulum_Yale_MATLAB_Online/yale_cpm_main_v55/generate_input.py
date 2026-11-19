"""Synthetic dyadic matrices for exact original 2D and 3D cpm_main comparison."""
from pathlib import Path
import hashlib,json,random
rng=random.Random(2026111955)
cases=[]
for i,(n,k) in enumerate([(12,4),(14,4),(16,16),(21,5),(27,6),(29,6),(33,4),(19,9)]):
    seed=20261550+i
    y=[rng.randint(-65,65)/16 for _ in range(n)]
    nodes=[5,5,4,4,6,6,7,3][i]
    mats=[]
    for outcome in y:
        m=[[0.0]*nodes for _ in range(nodes)]
        for col in range(nodes):
            for row in range(nodes):
                if i%2==0 and row>col:
                    continue
                weight=[1.25,-.875,.625,0,0][(row+col*2)%5]
                m[row][col]=outcome*weight+rng.randint(-55,55)/64
        if i%2==0:
            for row in range(nodes):
                for col in range(row):
                    m[row][col]=m[col][row]
        mats.append(m)
    cases.append(dict(id=f'V55_{i}_n{n}_k{k}',seed=seed,request=dict(three_d=dict(subject_matrices=mats),outcomes=y,k=k,p_threshold=.0625)))
p=Path(__file__).with_name('input.json')
p.write_text(json.dumps(cases,separators=(',',':'))+'\n')
p.with_name('input.sha256').write_text(hashlib.sha256(p.read_bytes()).hexdigest()+'  input.json\n')
