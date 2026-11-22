#!/usr/bin/env python3
"""NEW prospective original-first-blind V364 p9-12 single-reflector battery.

Neither MATLAB original numerical output nor original coefficients are used.
Public X/B and original-only source must be frozen before independent compiled
Rust prediction and strict scorer, both pushed before first original run.
Historical V340 FAIL immutable. Comprehensive V12 SEALED.
"""
from pathlib import Path
from collections import Counter
import hashlib,json,math,random,struct
ROOT=Path(__file__).resolve().parent
SEED=202611230364
NS=(19,31,48,65)
WIDTHS=tuple(range(1,17))
GAMMA=(1.,1.,-1.,2.,.125,4.,-.5,.75,1.5,.0625,3.,-2.,.25,1.25,-1.5,.875)
def hx(v):assert math.isfinite(v);return struct.pack('>d',float(v)).hex()
def main():
 cases=[]
 for seed_cohort in (0,1):
  for p in (9,10,11,12):
   for ni,n in enumerate(NS):
    for mode in ('dense','cancellation'):
     seed=SEED+seed_cohort*20000003+ni*100003+p*71233+sum(map(ord,mode))*119
     rng=random.Random(seed);a=[[0.]*n for _ in range(p)]
     a[0][0]=4.125 + seed_cohort*0.375
     for r in range(p,n-1):
      a[0][r]=((-1.)**(r+seed_cohort))*(.5+rng.random()*.7)*(2.**((r%7)-3) if mode=='cancellation' else 1.)
     for col in range(1,p):a[col][col]=2.**(-col)
     assert all(col[-1]==0. for col in a)
     b=[];base=[rng.gauss(0.,.6) for _ in range(n-1)]+[0.]
     for col in range(16):
      if col in (0,1):v=base.copy()
      elif col==9:v=b[8].copy()
      elif mode=='cancellation':
       v=[GAMMA[col]*((-1.)**(r+seed_cohort))*(2.**((r%9)-4)) + (.125*rng.gauss(0.,1.)) for r in range(n-1)]+[0.]
      else:v=[GAMMA[col]*base[r]+.12*rng.gauss(0.,1.) for r in range(n-1)]+[0.]
      b.append(v)
     assert b[0]==b[1] and b[8]==b[9] and all(c[-1]==0. for c in b)
     cases.append({'id':f'v364_{mode}_cohort{seed_cohort}_n{n}_p{p}_seed{seed}',
       'p':p,'n':n,'mode':mode,
       'a_colmajor_hex':[hx(v) for col in a for v in col],
       'b16_colmajor_hex':[hx(v) for col in b for v in col]})
 assert len(cases)==64 and Counter(c['p'] for c in cases)=={9:16,10:16,11:16,12:16}
 obj={'classification':'V364_NEW_GENUINE_FIRST_ORIGINAL_BLIND_P9P12_ONE_REFLECTOR_NUMERICAL_CHALLENGE',
  'source_original_MATLAB_numerical_data_consulted':False,
  'source_original_reads_Rust_forecast':False,
  'new_prospective_first_original_blind':True,
  'seed':SEED,'case_count':64,'widths':list(WIDTHS),'padding':[0,1,7,16],
  'V340_original_first_blind':'IMMUTABLE_FAIL_63871_OF_182784',
  'V332_original_first_blind':'PASS_261120_OF_261120',
  'V336_original_first_blind':'PASS_261120_OF_261120',
  'V363_source_disclosed':'EXACT_182784_OF_182784',
  'V12':'SEALED','cases':cases}
 raw=(json.dumps(obj,sort_keys=True,separators=(',',':'))+'\n').encode()
 dest=ROOT/'input.json';assert not dest.exists()
 dest.write_bytes(raw);sh=hashlib.sha256(raw).hexdigest()
 (ROOT/'input.sha256').write_text(sh+'  input.json\n')
 total=sum(c['p'] for c in cases)*4*sum(WIDTHS)
 assert total==365568
 print('V364 NEW first ORIGINAL BLIND raw X/B SHA',sh,'cases',len(cases),'total',total)
if __name__=='__main__':main()
