#!/usr/bin/env python3
r"""V334 genuinely NEW original-FIRST-BLIND adversarial full A\B numerical battery.

Public synthetic X/B only, with independent seed never used by V330.
Freeze original-only inputs, independent compiled Rust forecast and strict
scorer in PRIVATE remote commit BEFORE first original MATLAB R2026b run.
No actual MATLAB original outputs have been read or used for input creation.
The certificate is separate: V308 FAIL, V332 PASS and V12 SEALED remain.
"""
from collections import Counter
from pathlib import Path
import hashlib,json,math,random,struct

ROOT=Path(__file__).resolve().parent
SEED=202611220334
NS=(9,10,11,12,13,14,15,16,17,19,20,23,24,25,31,32,
    33,47,48,49,63,64,65,79,80,81,95,96,97,127,128,129)
FAMILIES=('near_collinear','row_dynamic_range','column_dynamic_range','cancellation')
WIDTHS=tuple(range(1,17))
PADDINGS=(0,1,7,16)
RHS_MULT=(1.,1.,-1.,2.,0.125,4.,-0.5,0.75,1.5,1.5,3.,-2.,0.25,1.25,-1.5,0.875)
def h(x):
 assert math.isfinite(x)
 return struct.pack('>d',float(x)).hex()
def main():
 cases=[]
 for case_i in range(64):
  p=7+(case_i%2)
  fam=FAMILIES[(case_i//2)%4]
  n=NS[(case_i*7 + case_i//8)%len(NS)]
  assert n>p
  seed=SEED+1000003*case_i
  rng=random.Random(seed)
  base=[rng.gauss(0.,1.) for _ in range(n-1)]+[0.]
  raw=[[rng.gauss(0.,1.) for _ in range(n-1)]+[0.] for j in range(p)]
  a=[]
  if fam=='near_collinear':
   eps=2.**(-(8+((case_i//8)%4)*4))
   for j in range(p):
    col=[(base[r]+eps*raw[j][r])*(2.**(j%3-1)) for r in range(n-1)]+[0.]
    a.append(col)
  elif fam=='row_dynamic_range':
   for j in range(p):
    col=[(raw[j][r]+0.2*base[r])*(2.**((r%17)-8)) for r in range(n-1)]+[0.]
    a.append(col)
  elif fam=='column_dynamic_range':
   for j in range(p):
    mul=2.**(j-(p//2))
    col=[(raw[j][r]+0.3*base[r])*mul for r in range(n-1)]+[0.]
    a.append(col)
  else:
   for j in range(p):
    col=[((-1.)**(r+j))*(0.6*base[r]+0.4*raw[j][r])+
         (0.1 if r==j else 0.) for r in range(n-1)]+[0.]
    a.append(col)
  beta=[rng.gauss(0.,1.) for _ in range(p)]
  signal=[sum(a[j][r]*beta[j] for j in range(p)) for r in range(n-1)]+[0.]
  baseline=[signal[r]+(0.08*rng.gauss(0.,1.) if fam!='near_collinear' else 0.003*rng.gauss(0.,1.)) for r in range(n-1)]+[0.]
  rhs=[]
  for k in range(16):
   if k in (0,1):v=baseline.copy()
   elif k==9:v=rhs[8].copy()
   else:
    v=[RHS_MULT[k]*baseline[r]+0.05*rng.gauss(0.,1.)+0.023*a[k%p][r] for r in range(n-1)]+[0.]
    if k in (5,11):
     v=[v[r]-RHS_MULT[k]*signal[r] for r in range(n-1)]+[0.]
   rhs.append(v)
  assert rhs[0]==rhs[1] and rhs[8]==rhs[9]
  assert all(col[-1]==0. for col in a+rhs)
  cases.append({'id':f'v334_{fam}_n{n}_p{p}_seed{seed}',
    'p':p,'n':n,'family':fam,'conditioning_epsilon':(2.**(-(8+((case_i//8)%4)*4)) if fam=='near_collinear' else None),
    'a_colmajor_hex':[h(x) for col in a for x in col],
    'rhs16_colmajor_hex':[h(x) for col in rhs for x in col]})
 assert len(cases)==64 and len({c['id'] for c in cases})==64
 assert Counter(c['p'] for c in cases)=={7:32,8:32}
 assert Counter(c['family'] for c in cases)==dict.fromkeys(FAMILIES,16)
 assert all(c['n']>c['p'] for c in cases)
 obj={'classification':'V334_NEW_GENUINE_FIRST_ORIGINAL_BLIND_ADVERSARIAL_WIDE_FULL_MLDIVIDE',
  'seed':SEED,'cohorts':64,'max_RHS_columns':16,
  'RHS_matrix_widths':list(WIDTHS),'padding_counts':list(PADDINGS),
  'first_original_blind_certificate_candidate':True,
  'original_numerical_results_seen_at_freeze':False,
  'original_MATLAB_can_access_Rust_prediction':False,
  'historical_V308':'IMMUTABLE_FAIL_54741_OF_57816',
  'historical_V332':'PASS_261120_OF_261120',
  'historical_V284':'PASS_1770_OF_1770',
  'universal_V12':'SEALED',
  'families':list(FAMILIES),
  'cases':cases}
 path=ROOT/'input.json'
 assert not path.exists(), 'new source-independent first-blind input immutable'
 raw=(json.dumps(obj,sort_keys=True,separators=(',',':'))+'\n').encode()
 path.write_bytes(raw)
 sh=hashlib.sha256(raw).hexdigest()
 (ROOT/'input.sha256').write_text(sh+'  input.json\n')
 assert sum(c['p'] for c in cases)*len(PADDINGS)*sum(WIDTHS)==261120
 print('V334 FIRST ORIGINAL BLIND ADVERARIAL INPUT SHA',sh,'cases',len(cases),'coefficients',261120,'bytes',len(raw))
 print('FAMILIES',Counter(c['family'] for c in cases),'MIN_MAX_N',min(c['n'] for c in cases),max(c['n'] for c in cases))
if __name__=='__main__':main()
