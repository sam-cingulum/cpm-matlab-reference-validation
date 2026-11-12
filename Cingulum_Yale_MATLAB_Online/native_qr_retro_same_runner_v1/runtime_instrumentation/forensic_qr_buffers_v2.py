#!/usr/bin/env python3
"""Validate and index authentic, source-disclosed MATLAB QR reflector buffers.
Does not execute or calibrate any model. This is retrospective evidence ONLY.
"""
import hashlib,json,pathlib,struct,sys,collections
P=pathlib.Path(__file__).resolve().parent
F=P/'reflector_capture_43233112468'
source=json.loads((P.parent.parent/'robustfit_raw_full_source_unseen_v1'/'input.json').read_bytes())
ref=json.loads((F/'qr_control_v5_clean.json').read_bytes())['records']
map_ref={v['id']:v for v in ref if v['iteration']==1}
inputs={}
for i in [0,1,6,12,23,47]:
 c=source['cases'][i]
 bits=tuple(f'{struct.unpack("<Q",struct.pack("<d",float(z)))[0]:016x}' for z in c['x'])
 inputs[bits]=c['id']
events=collections.defaultdict(list)
for line in (F/'matlab_qr_capture_buffers.log').read_text().splitlines():
 if not line.startswith('QR_BUFFER_EVENT\t'):continue
 d=dict(t.split('=',1) for t in line.split('\t')[1:] if '=' in t)
 m=int(d['m']); a=d['A_IN'].split(','); b=d['A_OUT'].split(',')
 assert len(a)==len(b)==m*2
 case=inputs.get(tuple(a[m:]));assert case,('UNMATCHED_PRIVATE_INPUT',m,d['seq'])
 assert int(d['info'])==0
 public=map_ref[case]
 qr_r=[b[0],'0000000000000000',b[m],b[m+1]]
 assert qr_r==public['R_hex'],('PRIVATE_R_MISMATCH',case,qr_r,public['R_hex'])
 assert int(d['jpvt_raw'],16)==public['pivot'][0],('PIVOT_FIRST_MISMATCH',case)
 events[case].append({'m':m,'raw_input':a,'private_A_out':b,'tau':d['tau'],'jpvt_raw':d['jpvt_raw'],'private_R_hex':qr_r})
assert len(events)==6 and sum(map(len,events.values()))==36
report={'scope':'RETROSPECTIVE_ORIGINAL_SYNTHETIC_SOURCE_DISCLOSED_ONLY',
        'matlab_run_id':'43233112468','events':36,
        'reference_sha256':hashlib.sha256((F/'qr_control_v5_clean.json').read_bytes()).hexdigest(),
        'cases':{}}
for case,records in events.items():
 assert len(records)==6,(case,len(records))
 assert all(x==records[0] for x in records[1:]),('UNSTABLE_PRIVATE_REFLECTOR',case)
 x=records[0]
 report['cases'][case]={'count':len(records),'m':x['m'],'tau_hex':x['tau'],
                         'jpvt_first_int64':int(x['jpvt_raw'],16),
                         'R_hex':x['private_R_hex'],
                         'full_private_A_out_sha256':hashlib.sha256(','.join(x['private_A_out']).encode()).hexdigest(),
                         'full_private_A_out_exact_across_6_calls':True}
(F/'forensic_qr_buffers_v2.json').write_text(json.dumps(report,indent=2,sort_keys=True)+'\n')
print('Genuine private MATLAB QR factor buffers: 6/6 cases; 36/36 snapshots matched; full A_out/tau bit stable across six calls/case; all public R bits and pivot first positions exact')
for name,x in report['cases'].items():print(name,x['m'],x['tau_hex'],x['jpvt_first_int64'])
