#!/usr/bin/env python3
"""V330 genuinely new first-ORIGINAL-blind p7/p8 multi-RHS acceptance battery.

Original MathWorks R2026b numerical results are NEVER inspected or available.
Only fresh public synthetic X and B from independent frozen seeds. Freeze new
source-only inputs, original executable, workflow and SHA before ever running
MathWorks; compiled pure Rust 261,120-bit forecast must be SHA-committed and
PUSHED to private remote before first original execution.
Historical V308 first-blind FAIL remains immutable and cannot be retrofitted.
"""
from collections import Counter
from pathlib import Path
import hashlib,json,math,random,struct
ROOT=Path(__file__).resolve().parent
SEED=202611220330
NS=(19,20,21,22,23,24,25,27,31,32,33,34,47,48,49,50,63,64,65,66,79,80,81,82,95,96,97,98,127,128,129,137)
FAMILIES=('dense','correlated','cancellation','row_scaled')
WIDTHS=tuple(range(1,17))
PADS=(0,1,7,16)
GAMMA=(1.,1.,-1.,2.,.125,4.,-.5,.75,1.5,.0625,3.,-2.,.25,1.25,-1.5,.875)
def hx(x):
 assert math.isfinite(x)
 return struct.pack('>d',float(x)).hex()
def main():
 cases=[]
 for index in range(64):
  p=7+index%2
  family=FAMILIES[(index//2)%4]
  n=NS[(index*11+index//4)%len(NS)]
  seed=SEED+index*1000003
  rng=random.Random(seed)
  a=[[0.]*n for _ in range(p)]
  common=[rng.gauss(0.,1.) for _ in range(n-1)]
  for j in range(p):
   for r in range(n-1):
    u=rng.gauss(0.,1.)
    if family=='dense':x=u
    elif family=='correlated':x=.89*common[r]+.28*u+(.125 if (j+r)%5==0 else 0.)
    elif family=='cancellation':x=(1. if (r+j)%2==0 else -1.)*(.45+.32*u)+.21*common[r]
    else:x=(2.**((r%11)-5))*(.72*u+.34*common[r])
    a[j][r]=x+(.09 if j==r else 0.)
  beta=[rng.gauss(0.,1.) for _ in range(p)]
  baseline=[sum(a[j][r]*beta[j] for j in range(p))+.15*rng.gauss(0.,1.) for r in range(n-1)]+[0.]
  b=[]
  for col in range(16):
   if col in (0,1):v=baseline.copy()
   elif col==9:v=b[8].copy() # another repeated value at a different panel lane
   else:v=[GAMMA[col]*baseline[r]+.11*rng.gauss(0.,1.)+.055*a[col%p][r] for r in range(n-1)]+[0.]
   b.append(v)
  assert b[0]==b[1] and b[8]==b[9]
  assert all(v[-1]==0. for v in a+b)
  cases.append({'id':f'v330_{family}_n{n}_p{p}_seed{seed}',
     'n':n,'p':p,'family':family,
     'a_colmajor_hex':[hx(x) for col in a for x in col],
     'rhs16_colmajor_hex':[hx(x) for col in b for x in col]})
 assert len(cases)==64 and len(set(c['id'] for c in cases))==64
 assert Counter(c['p'] for c in cases)=={7:32,8:32}
 assert Counter(c['family'] for c in cases)==dict.fromkeys(FAMILIES,16)
 assert all(c['n']>c['p'] for c in cases)
 obj={'classification':'V330_NEW_GENUINE_ORIGINAL_FIRST_BLIND_FULL_LENGTH_WIDE_TWO_LANE_MULTI_RHS',
      'seed':SEED,'cohorts':64,'max_RHS_columns':16,
      'RHS_matrix_widths':list(WIDTHS),'padding_counts':list(PADS),
      'first_original_blind_certificate_candidate':True,
      'source_original_MATLAB_numerical_results_seen':False,
      'original_mathworks_sees_native_forecast':False,
      'previous_first_blind_V308':'IMMUTABLE_FAIL_54741_OF_57816',
      'previous_first_blind_V284_single':'PASS_1770_OF_1770',
      'V252_full17':'FAIL','V263_reduced':'PASS_216_OF_216','V12':'SEALED',
      'cases':cases}
 raw=(json.dumps(obj,sort_keys=True,separators=(',',':'))+'\n').encode()
 dest=ROOT/'input.json'
 assert not dest.exists(),'first-original-blind inputs cannot be regenerated/overwritten'
 dest.write_bytes(raw)
 digest=hashlib.sha256(raw).hexdigest()
 (ROOT/'input.sha256').write_text(digest+'  input.json\n')
 total=sum(c['p'] for c in cases)*len(PADS)*sum(WIDTHS)
 assert total==261120
 print('V330 NEW FIRST ORIGINAL BLIND public inputs SHA',digest,
       'cases',len(cases),'comparisons',total,'raw bytes',len(raw))
if __name__=='__main__':main()
