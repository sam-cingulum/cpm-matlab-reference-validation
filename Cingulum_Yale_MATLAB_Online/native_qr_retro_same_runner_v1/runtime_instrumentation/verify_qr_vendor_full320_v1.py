#!/usr/bin/env python3
"""Genuine 320 raw case x vendor DLARF and DLARFG second reflector forensic; exact original R/h gate."""
import collections,hashlib,json,os,pathlib,re
P=pathlib.Path(__file__).resolve().parent
I=P.parent.parent/'qr_vendor_tree8_prospective_320_v1/input.json'
assert hashlib.sha256(I.read_bytes()).hexdigest()=='b03922f51ae9c5edc2bec7f68df01979d8f915ec0d8467179bbd580fa9871efe'
rows=json.loads(I.read_bytes())['cases'];assert len(rows)==320
by_x={tuple(x['x_hex']):x['id'] for x in rows};assert len(by_x)==320
clean=P/'qr_vendor_full320_clean.json';trace=P/'qr_vendor_full320_traced.json';log=P/'qr_vendor_full320_source.log'
s={'run_id':os.getenv('GITHUB_RUN_ID'),'trace_outcome':os.getenv('TRACE_OUTCOME')}
a,b=clean.read_bytes(),trace.read_bytes();aa=json.loads(a)['records'];bb=json.loads(b)['records'];assert len(aa)==len(bb)==960
s['clean_sha256']=hashlib.sha256(a).hexdigest();s['trace_sha256']=hashlib.sha256(b).hexdigest()
keys=('id','iteration','n','pivot','R_hex','robustfit_ok','robustfit_error','source_R_hex','source_h_hex','source_beta_hex','source_numeric_stats')
s['mismatched_record_fields']={k:sum(x[k]!=y[k] for x,y in zip(aa,bb)) for k in keys}
s['original_mathworks_bitwise_unchanged']=not any(s['mismatched_record_fields'].values())
assert s['original_mathworks_bitwise_unchanged'] and s['trace_outcome']=='success','ORIGINAL_SOURCE_RH_NONINTERFERENCE_FAILED'
reference={}
for r in aa:
 ident=r['id'];assert ident in set(by_x.values())
 if ident in reference:assert reference[ident]['R_hex']==r['R_hex'] and reference[ident]['source_h_hex']==r['source_h_hex']
 else:reference[ident]=r
assert len(reference)==320
samples=collections.defaultdict(list);overflows=[];unexpected=[];qr_count=[]
for line in log.read_text().splitlines():
 if line.startswith('QR_VENDOR_SECOND_SUMMARY\t'):
  d=dict(v.split('=',1) for v in line.split('\t')[1:] if '=' in v)
  overflows.append(int(d['overflow']));qr_count.append(int(d['total_qr']))
 if not line.startswith('QR_VENDOR_SECOND_EVENT\t'):continue
 d=dict(v.split('=',1) for v in line.split('\t')[1:] if '=' in v)
 raw=tuple(d['X_HEX'].split(','));ident=by_x.get(raw)
 if ident is None:
  if len(unexpected)<30:unexpected.append({'m':d['m'],'first_three_x':raw[:3]})
  continue
 assert len(raw)==reference[ident]['n'] and d['info']=='0'
 assert d['original_r12']==reference[ident]['R_hex'][2],('ORIGINAL_R12_RAW_SOURCE_MISMATCH',ident)
 assert [int(k) for k in d['pivot'].split(',')]==reference[ident]['pivot'],('ORIGINAL_SOURCE_PIVOT_MISMATCH',ident)
 assert d['vendor_dlarf_r12']==d['vendor_dgemv_r12']==d['original_r12'],('ORIGINAL_VENDOR_DGEMV_IS_NOT_DGEQP3',ident)
 assert int(d['dlarf_present'])==int(d['dgemv_present'])==int(d['ddot_present'])==int(d['dlarfg_present'])==1
 assert len(d['SECOND_A_HEX'].split(','))==len(d['DLARF_UPDATE_HEX'].split(','))==len(d['DLARFG_FINAL_HEX'].split(','))==len(raw)
 assert d['SECOND_A_HEX'].split(',')[0]==d['DLARFG_FINAL_HEX'].split(',')[0]==d['original_r12']
 assert d['SECOND_A_HEX'].split(',')[1]==reference[ident]['R_hex'][3]
 # Strictly do not assume tau2 or the complete second column must match
 samples[ident].append(d)
s.update({'distinct_original_raw_cases':len(samples),'source_vendor_scratch_events':sum(map(len,samples.values())),'unmatched_source_input_events':unexpected,'overflows':overflows,'total_original_qr_calls':sum(qr_count),'original_matlab_vendor_r12_exact_cases':sum(1 for v in samples.values() if v and v[0]['vendor_dgemv_r12']==v[0]['original_r12'])})
s['repeat_stable_source_vendor_dots']=all(len(v)==6 and all(item==v[0] for item in v) for v in samples.values())
second=collections.Counter();different=[]
for ident,events in samples.items():
 d=events[0];original=d['SECOND_A_HEX'].split(',');candidate=d['DLARFG_FINAL_HEX'].split(',')
 scores={
  'R12_exact':original[0]==candidate[0],
  'R22_exact':original[1]==candidate[1],
  'second_tail_exact':original[2:]==candidate[2:],
  'second_full_A_exact':original==candidate,
  'second_tau2_exact':d['tau2']==d['vendor_dlarfg_tau2'],
  'second_individual_A_exact':sum(x==y for x,y in zip(original,candidate)),
  'second_individual_A_total':len(original),
 }
 for key,v in scores.items():second[key]+=int(v)
 if not scores['second_full_A_exact']:different.append(ident)
s['second_householder_original_vendor_scores']=dict(second)
s['second_householder_divergent_case_ids']=different
s['original_vendor_dot_log_sha256']=hashlib.sha256(log.read_bytes()).hexdigest()
(P/'qr_vendor_full320_source_gate.json').write_text(json.dumps(s,indent=2,sort_keys=True)+'\n')
print('ORIGINAL_MATHWORKS_320_VENDOR_DGEMV_DOT_PROVENANCE',json.dumps(s,sort_keys=True))
assert s['distinct_original_raw_cases']==320 and s['source_vendor_scratch_events']==1920 and not unexpected,'ORIGINAL_VENDOR_DGEMV_COVERAGE_FAILED'
assert s['repeat_stable_source_vendor_dots'] and overflows and not any(overflows),'ORIGINAL_VENDOR_DGEMV_UNSTABLE_OR_OVERFLOW'
assert s['original_matlab_vendor_r12_exact_cases']==320,'ORIGINAL_VENDOR_DGEMV_R12_NOT_EXACT'
