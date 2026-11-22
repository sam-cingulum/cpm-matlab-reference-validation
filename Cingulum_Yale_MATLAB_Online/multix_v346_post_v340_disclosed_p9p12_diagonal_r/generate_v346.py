#!/usr/bin/env python3
"""V346 controlled original-only p9/p10/p11/p12 diagonal-R after V308 FAIL.

The only active Householder reflector is at pivot stage 0. Every remaining
pivot basis vector has positive diagonal, zero below; QR upper factor is
exactly diagonal in independent Rust. Original MATLAB outputs not consulted.
This source-DISCLOSED experiment cannot reclassify V308 original-first-blind.
"""
import hashlib,json,math,random,struct
from pathlib import Path
from collections import Counter
ROOT=Path(__file__).resolve().parent
NS=(19,31,48,65)
SEED=202611230346
WIDTHS=tuple(range(1,17))
GAMMA=(1.,1.,-1.,2.,0.125,4.,-0.5,0.75,1.5,0.0625,3.,-2.,0.25,1.25,-1.5,0.875)
def hx(v):
 assert math.isfinite(v)
 return struct.pack('>d',float(v)).hex()
def main():
 cases=[]
 for p in (9,10,11,12):
  for ni,n in enumerate(NS):
   for mode in ('dense','cancellation'):
    seed=SEED+ni*100003+p*71233+sum(map(ord,mode))*119
    rng=random.Random(seed)
    a=[[0.]*n for _ in range(p)]
    a[0][0]=4.125
    for r in range(p,n-1):
     a[0][r]=((-1.)**r)*(0.5+rng.random()*0.7)*(2.**((r%7)-3) if mode=='cancellation' else 1.)
    for col in range(1,p):
     a[col][col]=2.**(-col)
    assert all(col[-1]==0 for col in a)
    assert a[0][0]!=0 and all(a[0][r]==0 for r in range(1,p))
    b=[]
    base=[rng.gauss(0.,0.6) for _ in range(n-1)]+[0.]
    for col in range(16):
     if col in (0,1):
      v=base.copy()
     elif mode=='cancellation':
      v=[GAMMA[col]*((-1.)**r)*(2.**((r%9)-4))+(0.125*rng.gauss(0.,1.)) for r in range(n-1)]+[0.]
     else:
      v=[GAMMA[col]*base[r]+0.12*rng.gauss(0.,1.) for r in range(n-1)]+[0.]
     b.append(v)
    cases.append({'id':f'v346_{mode}_n{n}_p{p}_seed{seed}', 'p':p,'n':n,'mode':mode,
       'a_colmajor_hex':[hx(v) for col in a for v in col],
       'b16_colmajor_hex':[hx(v) for col in b for v in col]})
 assert len(cases)==32 and len(set(c['id'] for c in cases))==32
 assert Counter(c['p'] for c in cases)=={9:8,10:8,11:8,12:8}
 obj={'classification':'V346_POST_V340_DISCLOSED_P9P12_DIAGONAL_R_SINGLE_ACTIVE_REFLECTOR_ORIGINAL',
  'source_disclosed_after_V340':True,
  'V340_original_first_blind':'IMMUTABLE_FAIL_63871_OF_182784',
  'V332_original_first_blind':'PASS_261120_OF_261120',
  'V336_original_first_blind':'PASS_261120_OF_261120',
  'source_original_MATLAB_numerical_data_consulted':False,
  'original_first_blind_V308':'IMMUTABLE_FAIL_54741_OF_57816',
  'V284_solo_original_first_blind':'PASS_1770_OF_1770',
  'V12':'SEALED','seed':SEED,
  'case_count':32,'widths':list(WIDTHS),'padding':[0,1,7,16],
  'modes':['dense','cancellation'],'n_boundaries':list(NS),'cases':cases}
 dest=ROOT/'input.json'
 assert not dest.exists(),'source original-controlled input immutable'
 raw=(json.dumps(obj,sort_keys=True,separators=(',',':'))+'\n').encode()
 dest.write_bytes(raw)
 sha=hashlib.sha256(raw).hexdigest()
 (ROOT/'input.sha256').write_text(sha+'  input.json\n')
 print('V346 FROZEN PUBLIC ORIGINAL-ONLY CONTROLLED X/B SHA',sha,'raw bytes',len(raw),'cases',len(cases),
       'total coefficient positions',sum(c['p'] for c in cases)*4*sum(WIDTHS))
if __name__=='__main__':main()
