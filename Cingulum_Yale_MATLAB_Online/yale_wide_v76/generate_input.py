"""Fresh symmetric and asymmetric connectomes with hundreds to thousands of features."""
import hashlib,json,random
from pathlib import Path
rng=random.Random(7609128)
cases=[]
for i,(n,k,d,symmetric) in enumerate(((45,5,25,True),(63,6,46,True),(85,7,91,True),(59,6,23,False))):
    y=[rng.randrange(-150,151)/32 for _ in range(n)]
    matrices=[]
    for outcome in y:
        m=[[0.]*d for _ in range(d)]
        for j in range(d):
            for r in range(j+1 if symmetric else d):
                w=(.375,-.3125,.25,-.34375,0.,0.,0.)[(r+2*j)%7]
                m[r][j]=w*outcome+rng.randrange(-2**51,2**51)/2**51
                if symmetric:m[j][r]=m[r][j]
        matrices.append(m)
    cases.append(dict(id=f"wide_{d}_{n}",seed=760973+i,request=dict(three_d=dict(subject_matrices=matrices),outcomes=y,k=k,p_threshold=.01)))
p=Path(__file__).with_name("input.json")
p.write_text(json.dumps(cases,separators=(",",":"))+"\n")
p.with_suffix(".sha256").write_text(hashlib.sha256(p.read_bytes()).hexdigest()+"  input.json\n")
