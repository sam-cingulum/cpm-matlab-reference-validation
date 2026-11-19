"""Synthetic dyadic matrices for exact original 2D and 3D cpm_main comparison."""
from pathlib import Path
import hashlib,json,random
rng=random.Random(2026111950)
cases=[]
for i,(n,k) in enumerate([(12,4),(14,4),(18,6),(21,5),(24,24),(26,26),(25,3),(19,9)]):
    seed=20261500+i
    y=[rng.randint(-65,65)/16 for _ in range(n)]
    mats=[]
    for outcome in y:
        m=[[0.0]*5 for _ in range(5)]
        for col in range(5):
            for row in range(5):
                if i%2==0 and row>col:
                    continue
                weight=[1.25,-.875,.625,0,0][(row+col*2)%5]
                m[row][col]=outcome*weight+rng.randint(-55,55)/64
        if i%2==0:
            for row in range(5):
                for col in range(row):
                    m[row][col]=m[col][row]
        mats.append(m)
    cases.append(dict(id=f'V50_{i}_n{n}_k{k}',seed=seed,request=dict(three_d=dict(subject_matrices=mats),outcomes=y,k=k,p_threshold=.0625)))
p=Path(__file__).with_name('input.json')
p.write_text(json.dumps(cases,separators=(',',':'))+'\n')
p.with_name('input.sha256').write_text(hashlib.sha256(p.read_bytes()).hexdigest()+'  input.json\n')
