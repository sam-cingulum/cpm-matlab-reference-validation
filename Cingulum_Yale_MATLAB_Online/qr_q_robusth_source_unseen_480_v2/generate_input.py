#!/usr/bin/env python3
"""Independent source-blind adversarial QR full-A/tau binary64 holdout.

Entire new cohort. Exact binary64 transport. 40 lengths and 12 numerical
families chosen BEFORE any original MATLAB execution on these cases.
"""
import hashlib,json,math,random,struct
from pathlib import Path
SEED=202611132747
r=random.Random(SEED)
lengths=(9,10,11,12,15,16,17,18,19,20,23,24,25,26,28,29,30,31,32,33,34,35,36,39,40,41,43,44,45,47,48,55,56,57,63,64,65,71,97,128)
families=('gaussian','shifted','scaled','nearflat','alternating','impulse','tiny','large','heavy_tails','power_bands','clusters','ramped')
rows=[]
for n in lengths:
 for k in families:
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
  rows.append({'id':f'q_robusth_unseen480_{k}_n{n}_seed{SEED}','n':n,'scenario':k,'x_hex':tohex(xs),'y_hex':tohex(ys)})
assert len(rows)==480 and len({z['id'] for z in rows})==480
output={'schema':'CINGULUM_MATHWORKS_SOURCE_BLIND_Q_AND_ORIGINAL_ROBUSTFIT_H_480_V2','seed':SEED,'lengths':lengths,'scenarios':families,'cases':rows}
p=Path(__file__).with_name('input.json')
p.write_text(json.dumps(output,separators=(',',':'),sort_keys=True)+'\n')
print('SOURCE_UNSEEN_CHALLENGE_480_INPUT_SHA256',hashlib.sha256(p.read_bytes()).hexdigest())
