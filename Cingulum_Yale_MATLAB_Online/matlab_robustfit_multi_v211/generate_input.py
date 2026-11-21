#!/usr/bin/env python3
"""V211 FIRST-BLIND fresh genuine MATLAB R2026b raw multi-predictor robustfit.
Inputs only: no MATLAB result/intermediate in this generator. 48 cohorts,
4 raw feature widths (p=2,3,4,5), n=33,49,73, four conditioning families.
"""
import hashlib, json, random, struct
from pathlib import Path
SEED=202611220211
rng=random.Random(SEED)
families=('dense','correlated','scaled','offset')
sizes=(33,49,73)
widths=(2,3,4,5)
pack=lambda x:struct.pack('>d',float(x)).hex()
rows=[]
for n in sizes:
 for p in widths:
  for family in families:
   predictors=[]
   for j in range(p):
    values=[]
    for i in range(n):
     g=rng.gauss(0,1)
     if family=='dense':v=g
     elif family=='correlated' and j==p-1:v=predictors[0][i]+0.065*g
     elif family=='correlated':v=g
     elif family=='scaled':v=g*(2.**((j%5)-3))
     else:v=g*.3+(4.5 if j%2 else -2.1)
     values.append(v)
    predictors.append(values)
   coeff=[(j%2*2-1)*rng.uniform(.12,.75) for j in range(p)]
   y=[1.2+sum(coeff[j]*predictors[j][i] for j in range(p))
      +rng.gauss(0,.26)+(0.65 if i==n-1 and family=='dense' else 0.)
      for i in range(n)]
   ident=f'v211_{family}_n{n}_p{p}_seed{SEED}'
   rows.append(dict(id=ident,n=n,p=p,family=family,
       x_colmajor_hex=[pack(v) for col in predictors for v in col],
       y_hex=[pack(v) for v in y]))
assert len(rows)==48 and len({r['id'] for r in rows})==48
out=Path(__file__).with_name('input.json')
payload=dict(schema='CINGULUM_V211_R2026B_RAW_MULTIPREDICTOR_ROBUSTFIT_FIRST_BLIND',
             seed=SEED,cases=rows)
out.write_text(json.dumps(payload,sort_keys=True,separators=(',',':'))+'\n')
sha=hashlib.sha256(out.read_bytes()).hexdigest()
out.with_suffix('.sha256').write_text(sha+'  input.json\n')
print('V211 FIRST UNSEEN MULTIPREDICTOR INPUT SHA',sha)
