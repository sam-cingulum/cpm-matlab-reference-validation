#!/usr/bin/env python3
"""Validate original MathWorks vendor 480 raw binary64 GEMV and original QR/h gate.
No independent Rust forecast data is loaded here: source is self-consistent.
"""
import collections,hashlib,json,os,pathlib
D=pathlib.Path(__file__).resolve().parent
P=D.parent/'native_qr_retro_same_runner_v1/runtime_instrumentation'
IN=D/'input.tsv';EXPECTED_IN_SHA='d82b8f0537918b8f1f7190329830b8a963df2889d19f33b1f4bc37977a8cc670'
assert hashlib.sha256(IN.read_bytes()).hexdigest()==EXPECTED_IN_SHA
raw=[line.split('\t') for line in IN.read_text().strip().splitlines()]
assert len(raw)==480 and len({line[0] for line in raw})==480
ref={line[0]:int(line[1]) for line in raw}
a=P/'qr_vendor_source480_clean.json';b=P/'qr_vendor_source480_instrumented.json';log=P/'qr_vendor_source480_original_dots.log'
summary={'run':os.getenv('GITHUB_RUN_ID'),'instrumented_exit':os.getenv('INSTRUMENTED_EXIT'),'input_sha256':EXPECTED_IN_SHA,'precommitted_private_rust_commit':'e00a8840b33e849e135de628eb54be001a094376','precommitted_two_cpu_profiles_forecast_sha256':'7e904510378f6e6cd6811a9b9ac1712dfbb34e94e0ff3cc9fe89933f73f375dd'}
assert a.exists() and b.exists() and log.exists(),'ORIGINAL_SOURCE_OUTPUT_MISSING'
ba,bb=a.read_bytes(),b.read_bytes()
ra,rb=json.loads(ba)['records'],json.loads(bb)['records']
assert len(ra)==len(rb)==144
summary['source_clean_sha256']=hashlib.sha256(ba).hexdigest()
summary['source_instrumented_sha256']=hashlib.sha256(bb).hexdigest()
fields=('id','iteration','R_hex','source_R_hex','source_h_hex','pivot','source_equal_public')
summary['mismatched_original_source_records']={field:sum(x[field]!=y[field] for x,y in zip(ra,rb)) for field in fields}
summary['bitwise_original_R_h_unchanged']=not any(summary['mismatched_original_source_records'].values())
by_id={}
for line in log.read_text().splitlines():
 if line.startswith('QR_VENDOR_FROZEN_EVENT\t'):
  vals=dict(x.split('=',1) for x in line.split('\t')[1:] if '=' in x)
  id_=vals['id'];n=int(vals['n']);assert id_ in ref and ref[id_]==n and id_ not in by_id
  assert len(vals['vendor_dot'])==16 and int(vals['repeat'])==1
  int(vals['vendor_dot'],16)
  by_id[id_]=vals['vendor_dot']
 if line.startswith('QR_VENDOR_FROZEN_SUMMARY\t'):
  tail=dict(x.split('=',1) for x in line.split('\t')[1:] if '=' in x)
  summary['original_vendor_capture_info']=tail
summary['captured_original_vendor_count']=len(by_id)
summary['original_vendor_output_sha256']=hashlib.sha256(log.read_bytes()).hexdigest()
(P/'qr_vendor_source480_source_gate.json').write_text(json.dumps(summary,indent=2,sort_keys=True)+'\n')
print('ORIGINAL_MATHWORKS_DGEMV_SOURCE_BLIND_480',json.dumps(summary,sort_keys=True))
assert summary['instrumented_exit']=='success' and summary['bitwise_original_R_h_unchanged'],'ORIGINAL_SOURCE_BITWISE_NONINTERFERENCE_FAILED'
assert len(by_id)==480 and tail['count']=='480' and tail['failures']=='0' and tail['repeat_mismatches']=='0','ORIGINAL_VENDOR_480_SOURCE_INCOMPLETE'
assert int(tail['original_qr_calls'])>0,'ORIGINAL_MATHWORKS_DGEQP3_NOT_INVOKED'
