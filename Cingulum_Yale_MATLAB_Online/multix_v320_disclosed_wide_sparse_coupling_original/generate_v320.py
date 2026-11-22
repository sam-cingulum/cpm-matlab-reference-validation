#!/usr/bin/env python3
"""V320 SOURCE-DISCLOSED p7/p8 sparse coupling threshold test.

Probe 0, 1, 2, partial and all offdiagonal couplings into first QR row,
with original-only synthetic X/B and no genuine MATLAB outputs consulted.
V308 remains immutable original-first-blind FAIL.
"""
import hashlib,json,math,random,struct
from pathlib import Path
from collections import Counter
ROOT=Path(__file__).resolve().parent
SEED=202611220320
NS=(23,32,48,65)
PATTERNS=('none','last','first','first_last','odd','even','middle','all')
WIDTHS=(1,2,3,4,5,6,7,8,9,12,16)
GAMMA=(1.,1.,-1.,2.,0.125,4.,-0.5,0.75,1.5,0.0625,3.,-2.,0.25,1.25,-1.5,0.875)
def hx(v):
 assert math.isfinite(v)
 return struct.pack('>d',float(v)).hex()
def coupled(pattern,p):
 if pattern=='none':return set()
 if pattern=='last':return {p-1}
 if pattern=='first':return {1}
 if pattern=='first_last':return {1,p-1}
 if pattern=='odd':return {j for j in range(1,p) if j%2}
 if pattern=='even':return {j for j in range(1,p) if not j%2}
 if pattern=='middle':return {p//2}
 return set(range(1,p))
def main():
 cases=[]
 for p in (7,8):
  for ni,n in enumerate(NS):
   for pattern in PATTERNS:
    seed=SEED+ni*100003+p*71233+sum(map(ord,pattern))*119
    rng=random.Random(seed)
    a=[[0.]*n for _ in range(p)]
    a[0][0]=4.125
    for r in range(p,n-1):
     a[0][r]=((-1.)**r)*(0.5+rng.random()*0.7)*(2.**((r%7)-3))
    cs=coupled(pattern,p)
    for j in range(1,p):
     a[j][j]=2.**(-j)
     if j in cs:
      a[j][0]=a[j][j]*(2.**-6)*(1. if j%2 else -1.)
    assert all(col[-1]==0 for col in a)
    assert all(a[0][j]==0 for j in range(1,p))
    B=[]
    base=[rng.gauss(0.,0.6) for _ in range(n-1)]+[0.]
    for j in range(16):
     if j in (0,1):q=base.copy()
     else:q=[GAMMA[j]*base[r]+(0.08*rng.gauss(0.,1.)) for r in range(n-1)]+[0.]
     B.append(q)
    cases.append({'id':f'v320_{pattern}_n{n}_p{p}_seed{seed}', 'p':p,'n':n,
       'coupling_pattern':pattern,'coupled_basis_columns_onebased':[j+1 for j in sorted(cs)],
       'a_colmajor_hex':[hx(v) for col in a for v in col],
       'b16_colmajor_hex':[hx(v) for col in B for v in col]})
 assert len(cases)==64 and len(set(c['id'] for c in cases))==64
 assert Counter(c['coupling_pattern'] for c in cases)==dict.fromkeys(PATTERNS,8)
 obj={'classification':'V320_SOURCE_DISCLOSED_WIDE_P7P8_SPARSE_OFFDIAGONAL_COUPLING_ORIGINAL',
  'source_disclosed_after_V308':True,
  'source_original_MATLAB_numerical_data_consulted':False,
  'original_first_blind_V308':'IMMUTABLE_FAIL_54741_OF_57816',
  'V284_solo_original_first_blind':'PASS_1770_OF_1770',
  'V12':'SEALED','seed':SEED,'case_count':64,
  'widths':list(WIDTHS),'padding':[0,1,7],
  'coupling_patterns':list(PATTERNS),'n_boundaries':list(NS),'cases':cases}
 dest=ROOT/'input.json'
 assert not dest.exists(),'source original input cannot be overwritten'
 raw=(json.dumps(obj,sort_keys=True,separators=(',',':'))+'\n').encode()
 dest.write_bytes(raw)
 sh=hashlib.sha256(raw).hexdigest()
 (ROOT/'input.sha256').write_text(sh+'  input.json\n')
 print('V320 ORIGINAL PUBLIC INPUT SHA',sh,'raw bytes',len(raw),'cases',len(cases),
       'coefficients',sum(c['p'] for c in cases)*3*sum(WIDTHS))
if __name__=='__main__':main()
