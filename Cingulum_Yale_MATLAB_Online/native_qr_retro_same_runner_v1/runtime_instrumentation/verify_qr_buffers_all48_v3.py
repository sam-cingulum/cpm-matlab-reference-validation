#!/usr/bin/env python3
"""Strict genuine MATLAB 48-case x three repeats: normal exit, exact R/h and 288 private LAPACK snapshots."""
import collections, hashlib, json, os, pathlib, re, struct
P=pathlib.Path(__file__).resolve().parent
clean=P/'qr_control_v6_clean.json';captured=P/'qr_control_v6_captured.json';log=P/'matlab_qr_capture_buffers_all48.log'
summary={'workflow_run':os.getenv('GITHUB_RUN_ID'),'capture_action_outcome':os.getenv('CAPTURE_ACTION_OUTCOME'),'clean_exists':clean.exists(),'captured_exists':captured.exists(),'log_exists':log.exists()}
source=P.parent.parent/'robustfit_raw_full_source_unseen_v1'/'input.json'
assert hashlib.sha256(source.read_bytes()).hexdigest()=='36f70d7cfd31da808f4c5f61f1127e292597097287a21248782723436f26fa1b'
src=json.loads(source.read_bytes())['cases'];assert len(src)==48
keys=lambda x:tuple(f'{struct.unpack("<Q",struct.pack("<d",float(v)))[0]:016x}' for v in x)
by_x={keys(row['x']):row['id'] for row in src}
reference={}
if clean.exists() and captured.exists():
 a,b=clean.read_bytes(),captured.read_bytes();r=json.loads(a)['records'];q=json.loads(b)['records'];assert len(r)==len(q)==144
 summary['clean_sha256']=hashlib.sha256(a).hexdigest();summary['captured_sha256']=hashlib.sha256(b).hexdigest()
 summary['records']=len(r);summary['mismatched_records']={k:sum(x[k]!=y[k] for x,y in zip(r,q)) for k in ('id','iteration','R_hex','source_R_hex','source_h_hex','pivot')}
 summary['bitwise_exact']=not any(summary['mismatched_records'].values())
 for z in r:
  assert z['id'] in (row['id'] for row in src)
  if z['id'] in reference:assert (z['R_hex'],z['source_R_hex'],z['source_h_hex'],z['pivot'])==reference[z['id']]['datum'],('UNSTABLE_UNINSTRUMENTED',z['id'])
  else:reference[z['id']]={'datum':(z['R_hex'],z['source_R_hex'],z['source_h_hex'],z['pivot'])}
 assert len(reference)==48
snapshots=collections.defaultdict(list);unmatched=[];overflows=[]
if log.exists():
 for line in log.read_text().splitlines():
  if line.startswith('QR_BUFFER_SUMMARY\t'):
   m=re.search(r'overflow=(\d+)',line)
   if m:overflows.append(int(m.group(1)))
  elif line.startswith('QR_BUFFER_EVENT\t'):
   d=dict(x.split('=',1) for x in line.split('\t')[1:] if '=' in x)
   m=int(d['m']);aa=d['A_IN'].split(',');out=d['A_OUT'].split(',')
   assert m in (29,35,43,44,57,71) and int(d['n'])==2 and len(aa)==len(out)==2*m
   assert all(v=='3ff0000000000000' for v in aa[:m])
   cid=by_x.get(tuple(aa[m:]))
   if not cid:unmatched.append(d['seq']);continue
   assert d['info']=='0'
   ref=reference[cid]['datum']
   assert [out[0],'0000000000000000',out[m],out[m+1]]==ref[0],('INTERNAL_R_MISMATCH',cid)
   assert [int(d['jpvt_first']),int(d['jpvt_second'])]==ref[3],('INTERNAL_PIVOT_MISMATCH',cid)
   assert int(d['jpvt_abi'])==64,('UNEXPECTED_MATLAB_LAPACK_ABI',cid)
   snapshots[cid].append((out,d['tau'],d['jpvt_first'],d['jpvt_second']))
summary['buffer_events']=sum(map(len,snapshots.values()))+len(unmatched)
summary['cases_matched']=len(snapshots)
summary['case_event_counts']={k:len(v) for k,v in sorted(snapshots.items())}
summary['unmatched_buffer_events']=unmatched
summary['overflow_count']=sum(overflows)
summary['full_buffer_bitwise_stable_cases']=sum(int(all(s==ls[0] for s in ls)) for ls in snapshots.values())
(P/'qr_buffer_all48_v3_summary.json').write_text(json.dumps(summary,sort_keys=True,indent=2)+'\n')
print('QR_ALL48_GENUINE_INTERNAL_BUFFER_RESULT',json.dumps({k:v for k,v in summary.items() if k!='case_event_counts'},sort_keys=True))
assert clean.exists() and captured.exists() and summary['bitwise_exact'],'NUMERICAL_PARITY_FAILED'
assert summary['capture_action_outcome']=='success','MATLAB_PROCESS_FAILED'
assert len(snapshots)==48 and not unmatched,'ALL_48_SYNTHETIC_CASES_NOT_IDENTIFIED'
assert summary['buffer_events']==288 and all(len(v)==6 for v in snapshots.values()),'MISSING_PRIVATE_QR_BUFFER_EVENTS'
assert summary['full_buffer_bitwise_stable_cases']==48,'NONDETERMINISTIC_PRIVATE_REFLECTORS'
assert overflows and not any(overflows),'BUFFER_RING_OVERFLOW'
