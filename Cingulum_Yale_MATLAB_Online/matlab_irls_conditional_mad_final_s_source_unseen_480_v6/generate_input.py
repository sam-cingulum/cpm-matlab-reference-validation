#!/usr/bin/env python3
"""Independent source-blind adversarial QR full-A/tau binary64 holdout.

Entire new cohort. Exact binary64 transport. 12 source-certified lengths and 40 independently sampled numerical
families chosen BEFORE any original MATLAB execution on these cases.
"""
import hashlib,json,math,random,struct
from pathlib import Path
SEED=202611139313
r=random.Random(SEED)
lengths=(9,10,11,12,15,16,17,18,23,24,25,32)
families=('gaussian','shifted','scaled','nearflat','alternating','impulse','tiny','large','heavy_tails','power_bands','clusters','ramped')
rows=[]
for n in lengths:
 for replicate,k in enumerate(families*3 + families[:4]):
  xs=[]
  for i in range(n):
   a=r.gauss(0.0,1.0)
   if k=='gaussian':x=a
   elif k=='shifted':x=a*0.25+2.75
   elif k=='scaled':x=a*(2.0**(i%8-3))
   elif k=='nearflat':x=1.0+a*(2.0**-35)
   elif k=='alternating':x=(-1.0 if i%2 else 1.0)*(0.925+a*0.055)
   elif k=='impulse':x=a*0.025+(18.0 if i==n//3 else -11.5 if i==n//2 else 0.0)
   elif k=='tiny':x=a*2.0**-28
   elif k=='large':x=a*(2.0**24)
   elif k=='heavy_tails':x=a*a*a*0.19
   elif k=='power_bands':x=(1.0 if a>=0 else -1.0)*(2.0**((i%11)-5))
   elif k=='clusters':x=((-1.0 if i%3==0 else 1.0)+a*0.003)
   else:x=(i-n/2)*0.027+a*0.0001
   assert math.isfinite(x)
   xs.append(x)
  ys=[1.7+0.19*t+r.gauss(0,0.31) for t in xs]
  tohex=lambda arr:[struct.pack('>d',float(z)).hex() for z in arr]
  rows.append({'id':f'matlab_irls_conditional_unseen480_{k}_rep{replicate}_n{n}_seed{SEED}','n':n,'scenario':k,'replicate':replicate,'x_hex':tohex(xs),'y_hex':tohex(ys)})
assert len(rows)==480 and len({z['id'] for z in rows})==480
output={'schema':'CINGULUM_MATHWORKS_R2026B_SOURCE_UNSEEN_RAW_QR_QY_OLS_AND_CONDITIONAL_MAD_FINAL_S_480_V6','seed':SEED,'lengths':lengths,'scenarios':families,'cases':rows}
p=Path(__file__).with_name('input.json')
p.write_text(json.dumps(output,separators=(',',':'),sort_keys=True)+'\n')
print('SOURCE_UNSEEN_CHALLENGE_480_INPUT_SHA256',hashlib.sha256(p.read_bytes()).hexdigest())
