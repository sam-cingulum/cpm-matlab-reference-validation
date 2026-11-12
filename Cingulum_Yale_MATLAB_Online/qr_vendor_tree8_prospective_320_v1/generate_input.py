#!/usr/bin/env python3
"""Freeze 320 source-unseen raw binary64 QR and robustfit predictors.

Original MATLAB and source traces must NOT be executed until independent
compiled Rust prediction output and hash are committed and pushed.
"""
import hashlib,json,random,struct
from pathlib import Path
SEED=202611130399
r=random.Random(SEED)
lengths=(9,10,11,15,16,17,23,24,25,28,29,30,31,32,33,34,35,36,41,43,44,45,55,56,57,58,63,64,65,69,70,71,72,73,80,95,96,97,127,128)
scenarios=('baseline','outlier','rescaled','near_flat','offset','tiny','alternating','clustered')
rows=[]
for n in lengths:
 for scenario in scenarios:
  x=[]
  for i in range(n):
   z=r.gauss(0,0.81)
   if scenario=='baseline':value=z
   elif scenario=='outlier':value=z+(8.0 if i==n//3 else -5.0 if i==n//2 else 0.0)
   elif scenario=='rescaled':value=z*2048.0
   elif scenario=='near_flat':value=0.35+z*3e-7
   elif scenario=='offset':value=2.75+z
   elif scenario=='tiny':value=z*0.0001
   elif scenario=='alternating':value=(1.3+z/12.0) * (-1.0 if i%2 else 1.0)
   else:value=(-1.0 if i%4==0 else 1.0)+z/25.0
   x.append(value)
  y=[0.59+0.17*t+r.gauss(0,0.23) for t in x]
  hexf=lambda values:[struct.pack('>d',float(z)).hex() for z in values]
  rows.append({'id':f'unseen320_{scenario}_n{n}_seed{SEED}','n':n,'scenario':scenario,'x_hex':hexf(x),'y_hex':hexf(y)})
assert len(rows)==320 and len({x['id'] for x in rows})==320
p=Path(__file__).with_name('input.json')
p.write_text(json.dumps({'schema':'CINGULUM_MATHWORKS_SOURCE_UNSEEN_QR_R12_320_V1','seed':SEED,'lengths':lengths,'scenarios':scenarios,'cases':rows},sort_keys=True,separators=(',',':'))+'\n')
print('INPUT_SHA256',hashlib.sha256(p.read_bytes()).hexdigest(),'cases',len(rows),'lengths',len(lengths))
