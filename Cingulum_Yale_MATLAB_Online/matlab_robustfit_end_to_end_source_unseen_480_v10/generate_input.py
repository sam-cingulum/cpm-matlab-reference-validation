#!/usr/bin/env python3
"""V10 NEW raw x/y cohort for independent compiled Rust robustfit end-to-end
binary64 source-unseen certification. Never execute original MATLAB until the
complete V10 native Rust prediction AND scorer are committed/pushed publicly
verifiably with a pre-oracle seal. All cases distinct from V9.
"""
import hashlib,json,math,random,struct
from pathlib import Path
SEED=202611131906
r=random.Random(SEED)
lengths=(9,11,15,17,23,25)
families=('gaussian','shifted','scaled','nearflat','alternating','impulse',
          'tiny','large','heavy_tails','power_bands','clusters','ramped')
rows=[]
for n in lengths:
 for replicate,k in enumerate(families*4 + ('large',)*32):
  xs=[]
  for i in range(n):
   a=r.gauss(0.0,1.0)
   if k=='gaussian':x=a*0.85+0.1
   elif k=='shifted':x=a*0.21+2.93
   elif k=='scaled':x=a*(2.0**(i%9-4))
   elif k=='nearflat':x=1.07+a*(2.0**-35)
   elif k=='alternating':x=(-1.0 if i%2 else 1.0)*(0.81+a*0.062)
   elif k=='impulse':x=a*0.034+(21.0 if i==n//3 else -9.25 if i==n//2 else 0.0)
   elif k=='tiny':x=a*2.0**-29
   elif k=='large':x=a*(2.0**25)
   elif k=='heavy_tails':x=a*a*a*0.23
   elif k=='power_bands':x=(1.0 if a>=0 else -1.0)*(2.0**((i%10)-5))
   elif k=='clusters':x=((-1.0 if i%3==0 else 1.0)+a*0.0022)
   else:x=(i-n/2)*0.032+a*0.00012
   assert math.isfinite(x)
   xs.append(x)
  ys=[1.59+0.17*t+r.gauss(0,0.28) for t in xs]
  if k in ('impulse','heavy_tails') and replicate%2==1:ys[n//2]+=0.88
  pack=lambda z:struct.pack('>d',float(z)).hex()
  rows.append(dict(
    id=f'matlab_raw_robustfit_v10_unseen_{k}_rep{replicate}_n{n}_seed{SEED}',
    n=n,replicate=replicate,scenario=k,
    x_hex=[pack(z) for z in xs],y_hex=[pack(z) for z in ys]))
assert len(rows)==480 and len({z['id'] for z in rows})==480
p=Path(__file__).with_name('input.json')
data=dict(schema='CINGULUM_MATHWORKS_R2026B_RAW_XY_FULL_ROBUSTFIT_480_V10_SOURCE_UNSEEN',
  seed=SEED,lengths=lengths,scenarios=families,cases=rows)
p.write_text(json.dumps(data,separators=(',',':'),sort_keys=True)+'\n')
print('NEW_V10_SOURCE_UNSEEN_INPUT_SHA256',hashlib.sha256(p.read_bytes()).hexdigest())
