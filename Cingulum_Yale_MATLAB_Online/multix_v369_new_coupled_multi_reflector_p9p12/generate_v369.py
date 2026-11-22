#!/usr/bin/env python3
"""V369 prospective original-only NEW fully source-unseen coupled p9–12 matrices.

32 matrices with (a) two active Householder reflectors and non-diagonal R
and (b) multiple interacting reflector columns, row lengths 19/31/48/65.
Original code never imports Rust numerical coefficients. No MATLAB original
numerical outputs are known or used when generating this input.
"""
from pathlib import Path
from collections import Counter
import json,hashlib,math,random,struct
ROOT=Path(__file__).resolve().parent
SEED=202611230369
NS=(19,31,48,65)
P=(9,10,11,12)
FAMILIES=('two_reflector','coupled_reflectors')
def ieee(v):
 assert math.isfinite(v)
 return struct.pack('>d',float(v)).hex()
def main():
 cases=[]
 for p in P:
  for n in NS:
   for fam in FAMILIES:
    seed=SEED+p*23011+n*90311+sum(map(ord,fam))*37
    rng=random.Random(seed)
    x=[[0.]*n for _ in range(p)]
    x[0][0]=4.5
    for row in range(p,n-1):
     x[0][row]=((-1.)**row)*(0.9+0.4*rng.random())*(2.**((row%5)-2))
    for k in range(1,p):
     x[k][k]=2.**(-k)
    # Perturb x1's tail with an intentionally nonorthogonal combination of x0:
    # after the first Householder reflection this forces an active second
    # reflector, and offdiagonal R01 without changing the column pivot order.
    for row in range(p,n-1):
     x[1][row]=x[0][row]*.00625 + ((-1.)**row)*.0078125
    if fam=='coupled_reflectors':
     # Add genuine overlapping predictors, controlled small amplitudes:
     # creates R interactions beyond R01 and several active reflectors.
     for k in range(1,p):
      x[0][k]=(((-1.)**k)*2.**(-k))*0.0625
     for k in range(2,p):
      for row in range(p,n-1):
       x[k][row]=x[0][row]*(2.**(-k))*0.00625 + ((-1.)**(row+k))*.00390625*(2.**(-k))
      if k>=3:
       x[k][k-1]=(2.**(-k))*0.015625
    assert all(v[-1]==0. for v in x)
    base=[rng.gauss(0.,0.5) for _ in range(n-1)]+[0.]
    b=[]
    for j in range(16):
     if j in (0,1):q=base.copy()
     elif j==9:q=b[8].copy()
     elif fam=='coupled_reflectors':
      q=[base[row]*(1.+(j-8)/32.) + rng.gauss(0.,.19) for row in range(n-1)]+[0.]
     else:
      q=[((-1.)**(row+j))*(2.**((row+j)%7-3))*.3 + rng.gauss(0.,.09) for row in range(n-1)]+[0.]
     b.append(q)
    assert b[0]==b[1] and b[8]==b[9] and all(row[-1]==0. for row in b)
    cases.append({'id':f'v369_{fam}_n{n}_p{p}_seed{seed}',
     'n':n,'p':p,'family':fam,
     'a_colmajor_hex':[ieee(v) for col in x for v in col],
     'rhs16_colmajor_hex':[ieee(v) for col in b for v in col]})
 assert len(cases)==32
 assert Counter(c['p'] for c in cases)=={9:8,10:8,11:8,12:8}
 assert Counter(c['family'] for c in cases)==dict.fromkeys(FAMILIES,16)
 expected=sum(c['p'] for c in cases)*4*sum(range(1,17))
 assert expected==182784
 j={'classification':'V369_GENUINELY_NEW_SOURCE_ORIGINAL_UNSEEN_P9P12_COUPLED_MULTI_REFLECTOR_MLDIVIDE',
    'new_first_original_blind_candidate':True,
    'original_MATLAB_numerical_results_seen_before_freeze':False,
    'original_only_source_can_read_Rust_forecast':False,
    'seed':SEED,'case_count':32,'source_matrix_families':list(FAMILIES),
    'widths':list(range(1,17)),'paddings':[0,1,7,16],
    'new_source_original_unseen_coefficients':expected,
    'historical_V340_firstblind':'IMMUTABLE_FAIL_63871_OF_182784',
    'V366_firstblind':'PASS_365568_OF_365568','V12':'SEALED',
    'cases':cases}
 path=ROOT/'input.json'
 assert not path.exists()
 raw=(json.dumps(j,sort_keys=True,separators=(',',':'))+'\n').encode()
 path.write_bytes(raw)
 h=hashlib.sha256(raw).hexdigest()
 (ROOT/'input.sha256').write_text(h+'  input.json\n')
 print('V369 NEW COUPLED multi-reflector source X/B sha',h,'cases',len(cases),'firstblind coefficients',expected)
if __name__=='__main__':main()
