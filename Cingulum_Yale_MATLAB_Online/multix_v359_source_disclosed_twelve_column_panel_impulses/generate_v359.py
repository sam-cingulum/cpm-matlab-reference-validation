#!/usr/bin/env python3
"""V359 original-only 12-column panel impulse probe. No MATLAB outputs used."""
from pathlib import Path
import hashlib,json,random,math,struct
ROOT=Path(__file__).resolve().parent
BASE=ROOT.parent/'multix_v346_post_v340_disclosed_p9p12_diagonal_r/input.json'
SHA='75560b79e18c770ee24c6676abfe0de3c2f1460d2a4c30940deac075508b4abc'
def bits(v):assert math.isfinite(v);return struct.pack('>d',float(v)).hex()
def main():
 raw=BASE.read_bytes();assert hashlib.sha256(raw).hexdigest()==SHA
 src=json.loads(raw);cases=[]
 for old in src['cases']:
  p,n=old['p'],old['n']
  if n not in (48,65):continue
  rng=random.Random(202611230359+sum(map(ord,old['id'])))
  t=[p+1,(p+n)//2,n-3,n-2]
  assert len(set(t))==4 and all(p<=i<n-1 for i in t)
  b=[[0.]*n for _ in range(16)]
  b[0][0]=.5;b[0][t[0]]=.125
  b[1][0]=-.25;b[1][t[0]]=.375;b[1][t[1]]=-.375
  b[2][0]=.125
  for k,idx in enumerate(t):b[2][idx]=((-1.)**k)*2.**(-k-3)
  b[3]=[rng.gauss(0.,.3) for _ in range(n-1)]+[0.]
  for j in range(4,12):
   b[j]=[rng.gauss(0.,.3) for _ in range(n-1)]+[0.]
   b[j][0]+=(j-8)*.125
  for k in range(4):b[12+k]=b[k].copy()
  assert all(v[-1]==0. for v in b)
  assert all(b[k]==b[k+12] for k in range(4))
  cases.append({'id':old['id'],'p':p,'n':n,'mode':old['mode'],
   'a_colmajor_hex':old['a_colmajor_hex'],
   'b16_colmajor_hex':[bits(x) for col in b for x in col]})
 assert len(cases)==16
 out={'classification':'V359_SOURCE_DISCLOSED_POST_V340_GENUINE_ORIGINAL_12_COLUMN_PANEL_SPARSE_IMPULSES',
 'source_disclosed_after_V340':True,'MATLAB_original_numeric_values_seen_by_source':False,
 'V340':'IMMUTABLE_FAIL_63871_OF_182784','V332':'PASS_261120_OF_261120',
 'V336':'PASS_261120_OF_261120','V12':'SEALED',
 'V346_source_X_sha256':SHA,'case_count':16,'widths':[1,2,4,8,11,12,13,16],
 'padding':[0,1,7,16],'cases':cases}
 dest=ROOT/'input.json';assert not dest.exists()
 serialized=(json.dumps(out,sort_keys=True,separators=(',',':'))+'\n').encode()
 dest.write_bytes(serialized);h=hashlib.sha256(serialized).hexdigest()
 (ROOT/'input.sha256').write_text(h+'  input.json\n')
 print('V359 original-only source SHA',h,'cases',len(cases))
if __name__=='__main__':main()
