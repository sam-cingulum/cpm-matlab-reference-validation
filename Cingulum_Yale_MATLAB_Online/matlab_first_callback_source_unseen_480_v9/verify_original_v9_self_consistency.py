#!/usr/bin/env python3
"""Strict original-only first-callback self consistency; NEVER grades private Rust."""
import hashlib
import json
from pathlib import Path

p=Path(__file__).resolve().parent
source=p/'first_callback_v9_original_clean.json'
raw=p/'input.json'
assert hashlib.sha256(raw.read_bytes()).hexdigest()=='d85eb82d20f1293436c8d510026f63bb89f79be28346f67b839df11f46c7093d'
a=json.loads(source.read_bytes())
b=json.loads(raw.read_bytes())
assert a['release']=='2026b' and a['original_unmodified'] and a['callback_noninterference_asserted']
assert a['sealed_private_commit']=='189053c7c76bf0d6643dfec5cef0c85192d55dfb'
assert a['case_count']==480 and a['iterations']==2
assert len(a['records'])==960 and len(b['cases'])==480

original_fields=('Q_hex','source_R_hex','source_h_hex','source_Qy_hex',
 'source_ols_s_hex','source_std_y_hex','source_initial_beta_backslash_hex',
 'source_first_callback_u_hex','source_first_callback_w_hex',
 'source_callback_count','source_final_beta_hex','source_final_robust_s_hex','pivot')
count=0
for i,raw_case in enumerate(b['cases']):
 r=a['records'][i]
 t=a['records'][i+480]
 assert r['iteration']==1 and t['iteration']==2 and r['id']==raw_case['id']==t['id']
 assert r['n']==raw_case['n']==t['n']
 assert r['source_first_callback_noninterference'] and t['source_first_callback_noninterference']
 for field in original_fields:
  assert r[field]==t[field],f'original MATLAB non-repeatability at {raw_case["id"]} {field}'
 for field in ('source_first_callback_u_hex','source_first_callback_w_hex','source_h_hex'):
  assert len(r[field])==r['n']
  assert all(isinstance(v,str) and len(v)==16 for v in r[field])
 assert r['source_callback_count']>=3
 count+=1
report={'status':'GENUINE_MATLAB_R2026B_V9_ORIGINAL_FIRST_CALLBACK_SELF_REPEAT_STRICT_PASS',
 'cases':count,'complete_original_numeric_fields_exact_twice':count,
 'input_sha256':hashlib.sha256(raw.read_bytes()).hexdigest(),
 'original_source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),
 'original_source_callback_noninterference_asserted':True,
 'no_private_Rust_predictions_read_or_graded':True}
(p/'first_callback_v9_self_consistency.json').write_text(json.dumps(report,indent=2)+'\n')
print(report['status'],f'{count}/{count}',report['original_source_sha256'])
