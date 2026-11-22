#!/usr/bin/env python3
"""V408 NEW source-original-UNSEEN original-only Q basis QR certification.

64 totally new p9–12, n48/65 2-active-reflector matrices, 8 independent
random X designs per p,n pair; public R/Q1–2 and 4 zero-pad controls.
Generated without reading ANY original MATLAB numerical output or native
forecasts. Original source must wait for PRIVATE Rust forecast+strict scorer
to be SHA frozen, committed pushed and remotely verified.
"""
from pathlib import Path
from collections import Counter
import json,hashlib,math,random,struct
ROOT=Path(__file__).resolve().parent
SEED=202611230408
NS=(48,65)
PS=(9,10,11,12)
PADS=(0,1,7,16)
def hx(x):
 assert math.isfinite(x)
 return struct.pack('>d',float(x)).hex()
def main():
 cases=[]
 for p in PS:
  for n in NS:
   for replica in range(8):
    seed=SEED + p*131071 + n*65537 + replica*1009
    rng=random.Random(seed)
    x=[[0.]*n for _ in range(p)]
    x[0][0]=4.5+0.125*replica
    for row in range(p,n-1):
     scale=0.77+0.63*rng.random()
     x[0][row]=((-1.)**(row+replica))*(2.**((row+replica)%5-2))*scale
    for k in range(1,p):x[k][k]=2.**(-k)
    mix=0.00625+(replica%4)*0.0009765625
    for row in range(p,n-1):
     x[1][row]=x[0][row]*mix+(-1.)**(row+replica)*0.0078125*(1+(replica%3)*0.125)
    assert all(math.isfinite(v) for col in x for v in col)
    assert all(col[-1]==0. for col in x)
    assert all(x[0][k]==0. for k in range(1,p))
    assert all(x[1][k]==0. for k in range(2,p))
    assert all(x[k][i]==0. for k in range(2,p) for i in range(p,n))
    cases.append({'id':f'v408_NEW_Q_n{n}_p{p}_replica{replica}_seed{seed}',
      'n':n,'p':p,'design_replica':replica,
      'family':'two_reflector_new_source_unseen',
      'a_colmajor_hex':[hx(v) for col in x for v in col]})
 assert len(cases)==64
 assert Counter(c['p'] for c in cases)=={9:16,10:16,11:16,12:16}
 assert Counter(c['n'] for c in cases)=={48:32,65:32}
 count=sum(2*(c['n']+z) for c in cases for z in PADS)
 assert count==sum(2*(n+z)*8 for p in PS for n in NS for z in PADS)
 j={'classification':'V408_GENUINELY_NEW_FIRST_ORIGINAL_BLIND_TWO_REFLECTOR_Q_CROSS_AMD_64',
  'original_MATLAB_numerical_outputs_seen_before_frozen_native':False,
  'original_only_source_can_read_Rust_numerical_predictions':False,
  'new_source_original_unseen_candidate':True,
  'preoracle_private_Rust_forecast_plus_7_negative_controls_required':True,
  'seed':SEED,'case_count':64,'p_values':list(PS),'n_values':list(NS),
  'zero_paddings':list(PADS),'new_original_Q_first_two_column_bits':count,
  'prior_V397_source_disclosed':'PASS_4000_OF_4000_NOT_FIRSTBLIND',
  'historical_V400':'IMMUTABLE_FAIL_31336_OF_32000_Q',
  'historical_V407':'SOURCE_DISCLOSED_ONLY_PASS_32000_OF_32000_Q',
  'historical_V371':'IMMUTABLE_FAIL_133582_OF_182784',
  'historical_V366':'PASS_365568_OF_365568',
  'V12':'SEALED','cases':cases}
 path=ROOT/'input.json';assert not path.exists(),'never regenerate prior frozen input'
 raw=(json.dumps(j,sort_keys=True,separators=(',',':'))+'\n').encode()
 path.write_bytes(raw);sh=hashlib.sha256(raw).hexdigest()
 (ROOT/'input.sha256').write_text(sh+'  input.json\n')
 print('V408 NEW source-original-UNSEEN 64 matrix two-reflector public Q design SHA',sh,'bits',count)
if __name__=='__main__':main()
