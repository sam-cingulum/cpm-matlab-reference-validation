"""Fresh raw no-intercept and initial-unit-weight controls; no original outputs."""
import hashlib,json,random,struct
from pathlib import Path
bits=lambda x:struct.pack('>d',x).hex()
rng=random.Random(16344071)
weights=('andrews','bisquare','cauchy','fair','huber','logistic','talwar','welsch')
rows=[]
for j,n in enumerate((3,4,7,9,11,18,31,33,50,52,95,154,258,514,769,1025)):
    x=[rng.gauss(-.15,1.2) for _ in range(n)]
    if j%5==2:x=[-2.25 if j%2 else 1.75]*n
    y=[.15-.65*z+rng.gauss(0.,.55) for z in x]
    for k in range(1,min(n,2+j%3)):y[-k]+=(-1)**k*3.125
    if n>10:y[n//3]+=2.875
    for name in weights:
        for tune in (None,2.25+.25*(j%4)):
            rows.append(dict(id=f'no_intercept_v163_{j}_{name}_{"default" if tune is None else "tuned"}',n=n,
                x_hex=list(map(bits,x)),y_hex=list(map(bits,y)),weight_function=name,default_tune=tune is None,tune=tune))
for j,n in enumerate((5,9,17,33,50,95,258,769)):
    x=[rng.gauss(.1,1.) for _ in range(n)]
    y=[.7*z+rng.gauss(0.,.3) for z in x]
    for name in ('huber','talwar'):
        rows.append(dict(id=f'no_intercept_v163_unit_{j}_{name}',n=n,x_hex=list(map(bits,x)),y_hex=list(map(bits,y)),
            weight_function=name,default_tune=False,tune=128.))
p=Path(__file__).with_name('input.json');p.write_text(json.dumps(dict(cases=rows),separators=(',',':'))+'\n')
p.with_suffix('.sha256').write_text(hashlib.sha256(p.read_bytes()).hexdigest()+'  input.json\n')
