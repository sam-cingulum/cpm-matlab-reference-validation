#!/usr/bin/env python3
"""Fail-closed original MATLAB same-runner BLAS/R12 branch discrimination.

Retrospective source-disclosed reference, NOT pure Rust parity certification.
"""
import collections,hashlib,json,os,pathlib,struct
P=pathlib.Path(__file__).resolve().parent
INPUT=P.parent.parent/'robustfit_raw_full_source_unseen_v1'/'input.json'
assert hashlib.sha256(INPUT.read_bytes()).hexdigest()=='36f70d7cfd31da808f4c5f61f1127e292597097287a21248782723436f26fa1b'
rows=json.loads(INPUT.read_bytes())['cases'];assert len(rows)==48
bits=lambda v:f'{struct.unpack("<Q",struct.pack("<d",float(v)))[0]:016x}'
by_x={tuple(bits(z) for z in row['x']):row['id'] for row in rows}
assert len(by_x)==48
ca=P/'qr_vendor_second_clean.json';cb=P/'qr_vendor_second_traced.json'
log=P/'qr_vendor_second_actual.log'
s={'run_id':os.environ.get('GITHUB_RUN_ID'),'trace_step_outcome':os.environ.get('TRACE_OUTCOME'),'clean_exists':ca.exists(),'traced_exists':cb.exists(),'log_exists':log.exists()}
expected={}
if ca.exists() and cb.exists():
 a,b=ca.read_bytes(),cb.read_bytes()
 ra=json.loads(a)['records'];rb=json.loads(b)['records'];assert len(ra)==len(rb)==144
 s['clean_sha256']=hashlib.sha256(a).hexdigest();s['traced_sha256']=hashlib.sha256(b).hexdigest()
 s['mismatched_records']={key:sum(x[key]!=y[key] for x,y in zip(ra,rb)) for key in ('id','iteration','R_hex','source_R_hex','source_h_hex','pivot')}
 s['whole_source_bitwise_exact']=not any(s['mismatched_records'].values())
 for row in ra:
  key=row['id'];vals=(row['R_hex'],row['source_R_hex'],row['source_h_hex'],row['pivot'])
  if key in expected:assert expected[key]==vals,('ORIGINAL_SOURCE_REPEATS_CHANGED',key)
  else:expected[key]=vals
 assert len(expected)==48
snap=collections.defaultdict(list);unmatched=[];overflow=[];count_totals=[]
if log.exists():
 for line in log.read_text().splitlines():
  if line.startswith('QR_VENDOR_SECOND_SUMMARY\t'):
   d=dict(x.split('=',1) for x in line.split('\t')[1:] if '=' in x)
   overflow.append(int(d['overflow']));count_totals.append(int(d['total_qr']))
  elif line.startswith('QR_VENDOR_SECOND_EVENT\t'):
   d=dict(x.split('=',1) for x in line.split('\t')[1:] if '=' in x)
   m=int(d['m']);key=tuple(d['X_HEX'].split(','))
   ident=by_x.get(key)
   if ident is None:unmatched.append(key[:2]);continue
   assert m==len(key) and d['info']=='0'
   ref=expected[ident]
   assert d['original_r12']==ref[0][2],('SOURCE_WRAPPER_R12_MISMATCH',ident)
   assert list(map(int,d['pivot'].split(',')))==ref[3],('SOURCE_PIVOT_MISMATCH',ident)
   assert int(d['dlarf_present'])==1,('SOURCE_MKL_DLARF_MISSING',ident)
   snap[ident].append({k:d[k] for k in ('original_r12','vendor_dlarf_r12','vendor_dgemv_r12','vendor_ddot_r12','gemv_dot','ddot_dot','tau1','dlarf_present','dgemv_present','ddot_present')})
assert ca.exists() and cb.exists() and s['whole_source_bitwise_exact'],'VENDOR_INTERPOSITION_ALTERED_ORIGINAL_MATLAB_BITS'
assert s['trace_step_outcome']=='success','VENDOR_INTERPOSITION_EXIT_FAILED'
assert len(snap)==48 and not unmatched and all(len(v)==6 for v in snap.values()),'VENDOR_SECOND_EVENT_COVERAGE_MISSING'
assert overflow and not any(overflow),'VENDOR_SECOND_EVENT_OVERFLOW'
assert all(all(x==v[0] for x in v) for v in snap.values()),'VENDOR_SECOND_REPEAT_DRIFT'
score=collections.Counter();failed={k:[] for k in ('vendor_dlarf_r12','vendor_dgemv_r12','vendor_ddot_r12')}
for ident,rec in sorted(snap.items()):
 r=rec[0];score['cases']+=1
 for k in failed:
  if r[k]==r['original_r12']:score[k+'_exact']+=1
  else:failed[k].append(ident)
 for k in ('dgemv_present','ddot_present'):
  score[k+'_cases']+=int(r[k])
s.update({'case_count':len(snap),'capture_event_count':sum(map(len,snap.values())),'overflows':overflow,'qr_call_count':sum(count_totals),'nonmatching_x':unmatched,'scores':dict(score),'failures':failed})
(P/'qr_vendor_second_summary.json').write_text(json.dumps(s,indent=2,sort_keys=True)+'\n')
print('GENUINE_MATHWORKS_VENDOR_SECOND_UPDATE',json.dumps(s,sort_keys=True))
