#!/usr/bin/env python3
"""Source-unseen MathWorks QR A/B gate. Rust sealed forecasts scored separately."""
import collections
import hashlib
import json
import os
import pathlib
import re
import struct
P=pathlib.Path(__file__).resolve().parent
IN=P.parent.parent/'qr_pure_rust_prospective_v1'/'input.json'
assert hashlib.sha256(IN.read_bytes()).hexdigest()=='10ee2f2e6c98e1a09ae10297609306b90b40d5ca48bde6f1589397ad21aa1908'
original=json.loads(IN.read_bytes())['cases'];assert len(original)==72
bits=lambda v:f'{struct.unpack("<Q",struct.pack("<d",float(v)))[0]:016x}'
by_x={tuple(bits(v) for v in case['x']):case['id'] for case in original}
assert len(by_x)==72
clean=P/'qr_pure_rust_prospective_v1_clean.json'
trace=P/'qr_pure_rust_prospective_v1_trace.json'
log=P/'qr_pure_rust_prospective_v1_buffers.log'
s={'run':os.getenv('GITHUB_RUN_ID'),'capture_outcome':os.getenv('CAPTURE_ACTION_OUTCOME'),'clean_exists':clean.exists(),'trace_exists':trace.exists(),'log_exists':log.exists()}
by_case={}
if clean.exists() and trace.exists():
 a,b=clean.read_bytes(),trace.read_bytes();aa=json.loads(a)['records'];bb=json.loads(b)['records'];assert len(aa)==len(bb)==216
 s['clean_sha256']=hashlib.sha256(a).hexdigest();s['trace_sha256']=hashlib.sha256(b).hexdigest()
 s['mismatched_records']={field:sum(x[field]!=y[field] for x,y in zip(aa,bb)) for field in ('id','iteration','R_hex','pivot')}
 s['bitwise_exact']=not any(s['mismatched_records'].values())
 for row in aa:
  ident=row['id']
  if ident not in by_case:by_case[ident]=(row['R_hex'],row['pivot'])
  else:assert by_case[ident]==(row['R_hex'],row['pivot']),('ORIGINAL_QR_REPEAT_DRIFT',ident)
 assert len(by_case)==72
snapshots=collections.defaultdict(list);invalid=[];overflows=[]
if log.exists():
 for line in log.read_text().splitlines():
  if line.startswith('QR_BUFFER_SUMMARY\t'):
   m=re.search(r'overflow=(\d+)',line)
   if m:overflows.append(int(m.group(1)))
  elif line.startswith('QR_BUFFER_EVENT\t'):
   d=dict(x.split('=',1) for x in line.split('\t')[1:] if '=' in x)
   n=int(d['m']);aa=d['A_IN'].split(',');after=d['A_OUT'].split(',')
   assert n in (29,35,43,44,57,71) and int(d['n'])==2 and len(aa)==len(after)==2*n
   assert all(x=='3ff0000000000000' for x in aa[:n])
   ident=by_x.get(tuple(aa[n:]))
   if ident is None:invalid.append(d['seq']);continue
   assert int(d['info'])==0 and int(d['jpvt_abi'])==64
   ref_r,ref_p=by_case[ident]
   assert [after[0],'0000000000000000',after[n],after[n+1]]==ref_r,('QR_INTERNAL_R_DIFF',ident)
   assert [int(d['jpvt_first']),int(d['jpvt_second'])]==ref_p,('QR_INTERNAL_PIVOT_DIFF',ident)
   snapshots[ident].append((after,d['tau'],d['jpvt_first'],d['jpvt_second']))
s['captured_case_count']=len(snapshots)
s['buffer_events']=sum(map(len,snapshots.values()))+len(invalid)
s['invalid_buffer_events']=invalid;s['overflows']=overflows
s['stable_internal_cases']=sum(int(all(z==v[0] for z in v)) for v in snapshots.values())
(P/'qr_pure_rust_prospective_v1_summary.json').write_text(json.dumps(s,indent=2,sort_keys=True)+'\n')
print('ORIGINAL_MATLAB_PROSPECTIVE_CONTROL',json.dumps(s,sort_keys=True))
assert clean.exists() and trace.exists() and s['bitwise_exact'],'NUMERICAL_INSTRUMENTATION_FAILED'
assert s['capture_outcome']=='success','MATLAB_EXIT_FAILED'
assert len(snapshots)==72 and not invalid and s['buffer_events']==216,'NOT_ALL_ORIGINAL_CASES_CAPTURED'
assert all(len(v)==3 for v in snapshots.values()) and s['stable_internal_cases']==72,'PRIVATE_BUFFER_REPEAT_DRIFT'
assert overflows and not any(overflows),'BUFFER_CAPTURE_OVERFLOW'
