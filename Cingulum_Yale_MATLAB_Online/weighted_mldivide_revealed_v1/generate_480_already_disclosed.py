#!/usr/bin/env python3
"""Rebuild already-revealed MATLAB V9 weighted inputs for retrospective DORMQR.

The source first-callback weights were published in original run 43342252905.
These are *never* a new source-unseen experiment, and must not feed the native
Rust candidate: its original V9 forecasts independently regenerate all w.
"""
import gzip, hashlib, json
from pathlib import Path
HERE=Path(__file__).resolve().parent
V9=HERE.parent/'matlab_first_callback_source_unseen_480_v9'
SOURCE=V9/'source_runs/43342252905/first_callback_v9_original_clean.json.gz'
RAW=V9/'input.json'
RAW_SHA='d85eb82d20f1293436c8d510026f63bb89f79be28346f67b839df11f46c7093d'
SOURCE_GZIP_SHA='95829acc5434a380f851acd9bdc4603b13a94280110a3e29ac2687d8e5ee2edc'
SOURCE_ORIGINAL_SHA='229ca3f86046131854aca917f253e7c0861aded547992af81bbfda4e946fc49f'
assert hashlib.sha256(RAW.read_bytes()).hexdigest()==RAW_SHA
assert hashlib.sha256(SOURCE.read_bytes()).hexdigest()==SOURCE_GZIP_SHA
unzipped=gzip.decompress(SOURCE.read_bytes())
assert hashlib.sha256(unzipped).hexdigest()==SOURCE_ORIGINAL_SHA
data=json.loads(RAW.read_bytes())
src=json.loads(unzipped)
assert len(data['cases'])==480 and len(src['records'])==960
assert src['input_sha256']==RAW_SHA and src['case_count']==480
assert all(a['id']==b['id'] for a,b in zip(data['cases'],src['records'][:480]))
rows=[]
for original,rec in zip(data['cases'],src['records'][:480]):
    assert len(original['x_hex'])==len(original['y_hex'])==len(rec['source_first_callback_w_hex'])==original['n']
    rows.append(dict(id=original['id'],n=original['n'],x_hex=original['x_hex'],y_hex=original['y_hex'],
       w_hex=rec['source_first_callback_w_hex']))
out=dict(schema='ORIGINAL_MATHWORKS_R2026B_V9_DISCLOSED_480_WEIGHTED_BACKSLASH_DORMQR_INPUT',
  source_unseen=False, original_source_run='43342252905',
  original_source_sha256=SOURCE_ORIGINAL_SHA, original_raw_sha256=RAW_SHA,
  case_count=480,records=rows)
dest=HERE/'inputs_v9_480_disclosed.json'
dest.write_text(json.dumps(out,separators=(',',':'))+'\n')
sha=hashlib.sha256(dest.read_bytes()).hexdigest()
(HERE/'inputs_v9_480_disclosed.sha256').write_text(sha+'  '+dest.name+'\n')
print('DISCLOSED_V9_WLS_480_ONLY',sha,'bytes',dest.stat().st_size,'cases',len(rows))
