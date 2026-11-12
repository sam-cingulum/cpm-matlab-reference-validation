#!/usr/bin/env python3
"""Genuine R2026b source-unseen 320-case raw-bit and private QR provenance gate.

No independently predicted Rust values are present in this public oracle
workflow. They were frozen beforehand at private commit 4c35c98.
"""
import collections,hashlib,json,os,pathlib,re
P=pathlib.Path(__file__).resolve().parent
I=P.parent.parent/'qr_vendor_tree8_prospective_320_v1'/'input.json'
INPUT_SHA='b03922f51ae9c5edc2bec7f68df01979d8f915ec0d8467179bbd580fa9871efe'
assert hashlib.sha256(I.read_bytes()).hexdigest()==INPUT_SHA
cases=json.loads(I.read_bytes())['cases'];assert len(cases)==320
by_x={tuple(c['x_hex']):c['id'] for c in cases};assert len(by_x)==320
by_id={c['id']:c for c in cases}
a=P/'qr_vendor_tree8_320_clean.json';b=P/'qr_vendor_tree8_320_captured.json'
trace=P/'qr_vendor_tree8_320_private_buffers.log'
s={'run_id':os.getenv('GITHUB_RUN_ID'),'instrumented_exit':os.getenv('CAPTURE_OUTCOME'),'input_sha256':INPUT_SHA,'frozen_private_rust_commit':'4c35c9824e15283aff57993fecd12415d847d5a9','frozen_rust_pred_sha256':'9d832bfd4563bc0e55b68c9d00378b7591500c3ad779e5eca5d7d00c9a77257c','clean_exists':a.exists(),'captured_exists':b.exists(),'trace_exists':trace.exists()}
reference={};source_fail=[]
if a.exists() and b.exists():
 ca,cb=a.read_bytes(),b.read_bytes()
 aa=json.loads(ca)['records'];bb=json.loads(cb)['records'];assert len(aa)==len(bb)==960
 s['clean_sha256']=hashlib.sha256(ca).hexdigest();s['captured_sha256']=hashlib.sha256(cb).hexdigest()
 keys=('id','iteration','n','pivot','R_hex','robustfit_ok','robustfit_error','source_R_hex','source_h_hex','source_beta_hex','source_numeric_stats')
 s['unequal_records_by_field']={k:sum(x[k]!=y[k] for x,y in zip(aa,bb)) for k in keys}
 s['bitwise_noninterference']=not any(s['unequal_records_by_field'].values())
 for ix,(rec,expected) in enumerate(zip(aa,cases*3)):
  assert rec['id']==expected['id'] and rec['iteration']==ix//320+1
  assert rec['n']==expected['n'] and len(rec['R_hex'])==4
  if not rec['robustfit_ok']:
   if rec['id'] not in source_fail:source_fail.append(rec['id'])
  else:
   assert len(rec['source_R_hex'])==4 and len(rec['source_h_hex'])==rec['n']
   assert len(rec['source_beta_hex'])==2
  key=rec['id']
  nums=(rec['pivot'],rec['R_hex'],rec['robustfit_ok'],rec['source_R_hex'],rec['source_h_hex'],rec['source_beta_hex'],rec['source_numeric_stats'])
  if key in reference:assert reference[key]==nums,('ORIGINAL_MATHWORKS_REPETITION_DRIFT',key)
  else:reference[key]=nums
 assert len(reference)==320
s['original_robustfit_error_case_ids']=source_fail
snapshots=collections.defaultdict(list);invalid=[];overflows=[];selected=[]
if trace.exists():
 for line in trace.read_text().splitlines():
  if line.startswith('QR_BUFFER_SUMMARY\t'):
   match=re.search(r'selected=(\d+)\toverflow=(\d+)',line)
   if match:selected.append(int(match.group(1)));overflows.append(int(match.group(2)))
  if not line.startswith('QR_BUFFER_EVENT\t'):continue
  d=dict(item.split('=',1) for item in line.split('\t')[1:] if '=' in item)
  n=int(d['m']);before=d['A_IN'].split(',');after=d['A_OUT'].split(',')
  assert n>=9 and n<=128 and len(before)==len(after)==n*2 and int(d['n'])==2
  assert all(z=='3ff0000000000000' for z in before[:n]),'ORIGINAL_MATLAB_QR_WAS_NOT_ONES_X'
  ident=by_x.get(tuple(before[n:]))
  if ident is None:
   if len(invalid)<30:invalid.append({'n':n,'seq':d['seq'],'first_x':before[n:n+3]})
   continue
  assert n==by_id[ident]['n'] and d['info']=='0' and int(d['jpvt_abi'])==64
  r=reference[ident][1];pivot=reference[ident][0]
  assert [after[0],'0000000000000000',after[n],after[n+1]]==r,('PUBLIC_QR_R_NOT_REAL_SOURCE_BUFFER',ident)
  assert [int(d['jpvt_first']),int(d['jpvt_second'])]==pivot,('ORIGINAL_QR_PIVOT_MISMATCH',ident)
  snaps={'A_OUT':after,'TAU':d['tau'],'pivot':pivot}
  snapshots[ident].append(snaps)
s['private_capture_case_count']=len(snapshots)
s['private_capture_event_count']=sum(len(v) for v in snapshots.values())
s['private_capture_overflows']=overflows
s['private_capture_selected_counts']=selected
s['unmatched_original_raw_inputs']=invalid
s['stable_original_private_case_count']=sum(1 for v in snapshots.values() if v and all(z==v[0] for z in v))
(P/'qr_vendor_tree8_320_source_gate.json').write_text(json.dumps(s,indent=2,sort_keys=True)+'\n')
print('GENUINE_ORIGINAL_MATLAB_320_GATE',json.dumps(s,sort_keys=True))
assert a.exists() and b.exists() and s.get('bitwise_noninterference'),'SOURCE_R_H_INSTRUMENTATION_GATE_FAILED'
assert s['instrumented_exit']=='success','MATLAB_CAPTURE_PROCESS_FAILED'
assert len(snapshots)==320 and not invalid,'SOME_SOURCE_UNSEEN_RAW_CASES_NOT_CAPTURED'
assert all(len(v)==6 for v in snapshots.values()),'SOME_SOURCE_UNSEEN_QR_CALLS_MISSING'
assert s['stable_original_private_case_count']==320,'MATHWORKS_SOURCE_PRIVATE_QR_REPEAT_DRIFT'
assert overflows and not any(overflows),'SOURCE_PRIVATE_BUFFER_OVERFLOW'
