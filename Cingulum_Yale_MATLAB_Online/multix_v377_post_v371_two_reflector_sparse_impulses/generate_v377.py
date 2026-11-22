#!/usr/bin/env python3
"""V377 SOURCE-DISCLOSED post-V371 ORIGINAL-ONLY sparse two-reflector controls.

Uses only immutable V369 raw synthetic X; never reads any original MATLAB
numeric output or Rust candidate bits. Probe identical responses in RHS columns
0/12 etc and isolate first versus second Householder stage with e1/e0/e_p.
"""
from pathlib import Path
import hashlib,json,random,struct,math
ROOT=Path(__file__).resolve().parent
BASE=ROOT.parent/'multix_v369_new_coupled_multi_reflector_p9p12/input.json'
BASE_SHA='ed37acd5118b127caa4a46b3b7082c8a4d3007d6c208668902b91a6a1838f7ef'
SEED=202611230377
def bits(v):
 assert math.isfinite(v)
 return struct.pack('>d',float(v)).hex()
def main():
 raw=BASE.read_bytes();assert hashlib.sha256(raw).hexdigest()==BASE_SHA
 src=json.loads(raw)
 cases=[]
 for case in src['cases']:
  if case['family']!='two_reflector' or case['n'] not in (48,65):continue
  n=case['n'];p=case['p'];rng=random.Random(SEED+sum(map(ord,case['id'])))
  b=[[0.]*n for _ in range(16)]
  b[0][1]=1. # Second Householder HEAD only; first reflector orthogonal.
  b[1][0]=1. # First Householder HEAD input; second receives its reflected tail.
  b[2][p]=1. # One nonzero tail component.
  b[3][p+1]=1. # Another independent one-tail component.
  b[4][p]=1.;b[4][p+1]=1. # Two additive tail terms.
  b[5][p]=1.;b[5][p+1]=-1. # Two cancelling tail terms.
  for k in range(4):b[6][p+k]=(-1.)**k*2.**(-k)
  b[7]=[rng.gauss(0.,.25) for _ in range(n-1)]+[0.]
  b[8][2]=1. # Untouched sparse basis direction; should not affect first two.
  b[9]=b[8].copy()
  b[10][1]=1.;b[10][p]=.125
  b[11][1]=-1.;b[11][p+1]=.125
  for k in range(4):b[12+k]=b[k].copy()
  assert all(v[-1]==0. for v in b)
  assert all(b[k]==b[k+12] for k in range(4))
  assert b[8]==b[9]
  assert sum(v!=0 for v in b[0])==1 and sum(v!=0 for v in b[1])==1
  cases.append({'id':case['id'],'p':p,'n':n,'a_colmajor_hex':case['a_colmajor_hex'],
                'b16_colmajor_hex':[bits(v) for col in b for v in col],
                'source':'V369 public two-reflector exact QR design', 'family':'two_reflector'})
 assert len(cases)==8 and {c['p'] for c in cases}=={9,10,11,12}
 x={'classification':'V377_POST_V371_SOURCE_DISCLOSED_ORIGINAL_ONLY_TWO_REFLECTOR_SPARSE_IMPULSES',
    'source_disclosed_after_V371':True,
    'original_MATLAB_numerical_results_consulted':False,
    'original_source_reads_independent_Rust_forecast':False,
    'V369_original_only_input_SHA256':BASE_SHA,
    'new_source_probe_seed':SEED,'case_count':len(cases),
    'widths':[1,2,4,8,11,12,13,16],
    'padding':[0,1,7,16],
    'V371_first_original_blind':'IMMUTABLE_FAIL_133582_OF_182784',
    'V366_first_original_blind':'PASS_365568_OF_365568','V12':'SEALED',
    'cases':cases}
 dest=ROOT/'input.json';assert not dest.exists()
 encoded=(json.dumps(x,sort_keys=True,separators=(',',':'))+'\n').encode()
 dest.write_bytes(encoded);h=hashlib.sha256(encoded).hexdigest()
 (ROOT/'input.sha256').write_text(h+'  input.json\n')
 print('V377 original-only sparse source SHA',h,'cases',len(cases))
if __name__=='__main__':main()
