#!/usr/bin/env python3
"""V252 FIRST-ORIGINAL-BLIND new full multi-X robustfit raw-only challenge.

New seed and different row counts compared with V211. 48 source-inaccessible
prospective cohorts, original X/y ONLY, never any MathWorks numeric result.
Four conditioning families including adversarial terminal outlier designed
to exercise source p2 trailing-zero Householder support.
"""
import hashlib
import json
import random
import struct
from pathlib import Path

SEED=202611220252
ROWS=(35,61,87)
WIDTHS=(2,3,4,5)
FAMILIES=('dense','correlated','scaled','terminal_outlier')
rng=random.Random(SEED)
pack=lambda x:struct.pack('>d',float(x)).hex()
cohorts=[]
for n in ROWS:
 for p in WIDTHS:
  for family in FAMILIES:
   x=[]
   for j in range(p):
    col=[]
    for i in range(n):
     g=rng.gauss(0.,1.)
     if family=='correlated' and j==p-1:
      v=x[0][i]+0.047*g
     elif family=='scaled':
      v=g*(2.0**(j-2))
     elif family=='terminal_outlier':
      v=g*(0.57 if j%2 else 1.0)
     else:
      v=g
     col.append(v)
    x.append(col)
   coefficients=[(-1. if j%2 else 1.)*rng.uniform(.15,.73) for j in range(p)]
   y=[0.85+sum(coefficients[j]*x[j][i] for j in range(p))
      +rng.gauss(0.,.23)
      +(1.6 if family=='terminal_outlier' and i==n-1 else 0.)
      for i in range(n)]
   ident=f'v252_{family}_n{n}_p{p}_seed{SEED}'
   cohorts.append({'id':ident,'n':n,'p':p,'family':family,
      'x_colmajor_hex':[pack(v) for col in x for v in col],
      'y_hex':[pack(v) for v in y]})
assert len(cohorts)==48 and len({c['id'] for c in cohorts})==48
assert len({h for c in cohorts for h in c['y_hex']})>2000
root=Path(__file__).resolve().parent
payload={'schema':'CINGULUM_V252_R2026B_FULL_17_MULTIX_FIRST_ORIGINAL_BLIND',
 'seed':SEED,'cases':cohorts}
raw=json.dumps(payload,sort_keys=True,separators=(',',':'))+'\n'
(root/'input.json').write_text(raw)
sha=hashlib.sha256((root/'input.json').read_bytes()).hexdigest()
(root/'input.sha256').write_text(sha+'  input.json\n')
print('V252 RAW-ONLY PREORACLE INPUT SHA256',sha)
