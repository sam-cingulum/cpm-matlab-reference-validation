#!/usr/bin/env python3
"""Compare independent ORIGINAL MathWorks R2026b process outputs, bit for bit.

This is oracle reproducibility diagnostics, not a native Rust predictor or a
license-free substitute for MATLAB. Does not choose algorithms from references.
"""
import argparse,collections,hashlib,json,pathlib,re
arg=argparse.ArgumentParser()
arg.add_argument('first');arg.add_argument('second')
arg.add_argument('--fingerprint-first');arg.add_argument('--fingerprint-second')
arg.add_argument('--output')
a=arg.parse_args()
def load(name):
 p=pathlib.Path(name);v=p.read_bytes();rec=json.loads(v)['records']
 by=collections.defaultdict(list)
 for r in rec:by[r['id']].append(r)
 assert all(len(v)==3 for v in by.values())
 for name,rr in by.items():
  assert all((x['R_hex'],x['source_R_hex'],x['source_h_hex'],x['pivot'])==(rr[0]['R_hex'],rr[0]['source_R_hex'],rr[0]['source_h_hex'],rr[0]['pivot']) for x in rr),('UNSTABLE_WITHIN_RUN',name)
 return hashlib.sha256(v).hexdigest(),{k:v[0] for k,v in by.items()}
sha,first=load(a.first);shb,second=load(a.second)
common=sorted(set(first)&set(second))
count={'cases':len(common),'case_ids':common,'first_sha256':sha,'second_sha256':shb,
 'first_cases':len(first),'second_cases':len(second)}
for k in ('R_hex','source_R_hex','source_h_hex'):
 total=exact=complete=0;case_diffs=[]
 for id in common:
  x,y=first[id][k],second[id][k]
  assert len(x)==len(y),(k,id)
  matched=sum(v==w for v,w in zip(x,y))
  exact+=matched;total+=len(x);complete+=int(matched==len(x))
  if matched!=len(x):case_diffs.append({'id':id,'exact':matched,'total':len(x)})
 count[k]={'exact':exact,'total':total,'full_cases':complete,'differing_cases':case_diffs}
count['identical_pivots']=sum(first[id]['pivot']==second[id]['pivot'] for id in common)
for label,path in [('first',a.fingerprint_first),('second',a.fingerprint_second)]:
 if not path:continue
 txt=pathlib.Path(path).read_text()
 def find(k):
  m=re.search(r'^'+re.escape(k)+r':\s*(.*)$',txt,re.M)
  return m.group(1).strip() if m else None
 libs={}
 for line in txt.splitlines():
  if re.match(r'^[a-f0-9]{64}\s+',line):
   digest,where=line.split(None,1);libs[pathlib.Path(where).name]=digest
 count[label+'_host']={'Model name':find('Model name'),'Vendor ID':find('Vendor ID'),
  'CPU(s)':find('CPU(s)'),'Kernel':next((x for x in txt.splitlines() if x.startswith('Linux ')),None),
  'MATLAB_runtime_binary_sha256':libs}
print('GENUINE_MATHWORKS_CROSS_RUN_BITWISE',json.dumps({k:v for k,v in count.items() if k!='case_ids'},sort_keys=True))
if a.output:pathlib.Path(a.output).write_text(json.dumps(count,indent=2,sort_keys=True)+'\n')
