#!/usr/bin/env python3
r"""NEW original-FIRST-BLIND p9–12 full-length multi-RHS genuine MATLAB battery.

The original MathWorks solver must be run only AFTER a source-independent
compiled Rust forecast and strict untouched scorer are SHA-frozen on the
private remote. On fail, keep new V340 verdict FAIL forever.
"""
import hashlib,json,math,random,struct
from collections import Counter
from pathlib import Path

BASE=Path(__file__).resolve().parent
SEED=202611220338
FAMILIES=("dense","correlated","cancellation","row_scaled")
WIDTHS=tuple(range(1,17))
PADS=(0,1,7,16)
NS=(15,16,17,19,20,23,24,25,31,32,33,47,48,49,63,64,65,79,80,81,95,96,97,127,128,129,137,149,160,161,191,193)
SCALE=(1.,1.,-1.,2.,.125,4.,-.5,.75,1.5,1.5,3.,-2.,.25,1.25,-1.5,.875)
def hex64(x):
 assert math.isfinite(x)
 return struct.pack('>d',float(x)).hex()
def main():
 cases=[]
 for i in range(32):
  p=9+(i%4)
  family=FAMILIES[(i//4)%4]
  n=NS[(i*9 + i//8)%len(NS)]
  assert n>p
  seed=SEED+i*1000003
  rng=random.Random(seed)
  base=[rng.gauss(0.,1.) for r in range(n-1)]+[0.]
  X=[]
  for j in range(p):
   col=[]
   for r in range(n-1):
    z=rng.gauss(0.,1.)
    if family=="dense":x=z+(0.1 if r==j else 0.)
    elif family=="correlated":x=.68*base[r]+.52*z+(0.16 if r==j else 0.)
    elif family=="cancellation":x=(-1. if (r+j)%2 else 1.)*(.56*z+.4*base[r])+(0.12 if r==j else 0.)
    else:x=(z+.28*base[r])*(2.**((r%13)-6))
    col.append(x)
   col.append(0.)
   X.append(col)
  beta=[rng.gauss(0.,1.) for j in range(p)]
  base_y=[sum(X[j][r]*beta[j] for j in range(p))+.13*rng.gauss(0.,1.) for r in range(n-1)]+[0.]
  Y=[]
  for j in range(16):
   if j in (0,1):col=base_y.copy()
   elif j==9:col=Y[8].copy()
   else:col=[SCALE[j]*base_y[r]+.1*rng.gauss(0.,1.)+.035*X[j%p][r] for r in range(n-1)]+[0.]
   Y.append(col)
  assert Y[0]==Y[1] and Y[8]==Y[9]
  assert all(col[-1]==0. for col in X+Y)
  cases.append({'id':f'v338_{family}_n{n}_p{p}_seed{seed}',
   'p':p,'n':n,'family':family,
   'a_colmajor_hex':[hex64(v) for col in X for v in col],
   'rhs16_colmajor_hex':[hex64(v) for col in Y for v in col]})
 assert len(cases)==32 and len(set(c['id'] for c in cases))==32
 assert Counter(c['p'] for c in cases)=={9:8,10:8,11:8,12:8}
 assert Counter(c['family'] for c in cases)==dict.fromkeys(FAMILIES,8)
 original={'classification':'V338_NEW_GENUINE_ORIGINAL_FIRST_BLIND_P9P12_FULL_MLDIVIDE',
  'seed':SEED,'cohorts':32,'max_RHS_columns':16,
  'first_original_blind_certificate_candidate':True,
  'original_numerical_results_seen_at_freeze':False,
  'original_MATLAB_can_access_Rust_prediction':False,
  'historical_V308':'IMMUTABLE_FAIL_54741_OF_57816',
  'historical_V332':'PASS_261120_OF_261120',
  'historical_V336':'PASS_261120_OF_261120',
  'universal_V12':'SEALED',
  'RHS_matrix_widths':list(WIDTHS),'padding_counts':list(PADS),
  'families':list(FAMILIES),'cases':cases}
 raw=(json.dumps(original,separators=(',',':'),sort_keys=True)+'\n').encode()
 path=BASE/'input.json'
 assert not path.exists(),'first-original-blind original-only source input immutable'
 path.write_bytes(raw)
 digest=hashlib.sha256(raw).hexdigest()
 (BASE/'input.sha256').write_text(digest+'  input.json\n')
 total=sum(c['p'] for c in cases)*len(PADS)*sum(WIDTHS)
 assert total==182784
 print('V338 ORIGINAL-ONLY 32 NEW P9-P12 COHORTS',total,'IEEE754 coefficients; raw SHA',digest,'bytes',len(raw))
if __name__=='__main__':main()
