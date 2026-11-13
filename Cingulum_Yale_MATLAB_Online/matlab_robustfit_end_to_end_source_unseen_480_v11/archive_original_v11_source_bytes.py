#!/usr/bin/env python3
"""Lossless, SHA-sealed public archive of ORIGINAL source-unseen V11 MATLAB output.

The complete unmodified MathWorks original run has already finished:
https://github.com/sam-cingulum/cpm-matlab-reference-validation/actions/runs/43367517837
Preserve every numeric binary64 hex with reversible gzip, never rounding JSON
numbers, converting hex, or rewriting source fields. Original source verdict
remains separate from independently calculated preoracle Rust adjudication.
"""
import gzip,hashlib,json,pathlib
HERE=pathlib.Path(__file__).resolve().parent
RUN_ID='43367517837'
SOURCE=HERE/f'source_run_{RUN_ID}'
TARGET=HERE/'source_runs'/RUN_ID
FILES=[
 'original_v11_480_raw_full_robustfit_clean.json',
 'original_v11_source_self_consistency.json',
 'original_v11_cpu_and_vendor_fingerprint.txt',
 'original_v11_original_sha256_manifest.txt']
assert all((SOURCE/p).exists() for p in FILES),'Missing full original numerical source output'
TARGET.mkdir(parents=True,exist_ok=True)
rows=[]
for name in FILES:
 b=(SOURCE/name).read_bytes()
 encoded=gzip.compress(b,compresslevel=9,mtime=0)
 archive=TARGET/(name+'.gz')
 archive.write_bytes(encoded)
 assert gzip.decompress(archive.read_bytes())==b
 rows.append(dict(
  original_filename=name,original_sha256=hashlib.sha256(b).hexdigest(),
  archived_filename=archive.name,archived_gzip_sha256=hashlib.sha256(encoded).hexdigest(),
  original_bytes=len(b),gzip_bytes=len(encoded)))
source=json.loads((SOURCE/FILES[0]).read_bytes())
assert source['status']=='ORIGINAL_MATHWORKS_R2026B_FULL_ROBUSTFIT_480_V11_SOURCE_UNSEEN'
assert source['case_count']==480 and source['original_repetitions']==2
assert len(source['records'])==960
assert source['new_input_sha256']=='1144418910dc6a81ba3b98f9540fe914ac796d9a9bab25ce75f6c1ef2ace2f53'
assert source['pre_oracle_native_Rust_frozen_forecast_sha256']=='c633624b9867e2a273fda4d0cd2fafa50ec6b749b3eba2fca9e896f1d0b8335f'
assert 'AMD EPYC' in (SOURCE/FILES[2]).read_text()
manifest=dict(status='LOSSLESS_ORIGINAL_MATHWORKS_R2026B_V11_FIRST_SOURCE_UNSEEN_RUN_PUBLIC_ARCHIVE',
 original_run=RUN_ID,original_source_public_commit='d0570e6b9cca0c1dc0fa2a1d38c67d20f71051cb',
 frozen_native_private_preoracle_commit='997b3f8714e655d7d600c3e0c529d15cd7230fb1',
 frozen_native_private_preoracle_SHA256='c633624b9867e2a273fda4d0cd2fafa50ec6b749b3eba2fca9e896f1d0b8335f',
 original_ran_twice_per_480_case=True,first_original_exposure_to_v11=True,
 irreversible_numeric_rewrite=False,compression_is_exact_lossless=True,
 files=rows)
m=TARGET/'SOURCE_ORIGINAL_SHA256_MANIFEST.json'
m.write_text(json.dumps(manifest,indent=2,sort_keys=True)+'\n')
for item in rows:
 assert hashlib.sha256(gzip.decompress((TARGET/item['archived_filename']).read_bytes())).hexdigest()==item['original_sha256']
print('ORIGINAL_MATLAB_V11_FULL_480_ARCHIVE_SHA256',hashlib.sha256(m.read_bytes()).hexdigest())
for r in rows:print(r['original_filename'],r['original_sha256'],'compressed',r['gzip_bytes'])
