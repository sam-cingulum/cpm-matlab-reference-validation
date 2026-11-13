#!/usr/bin/env python3
"""Verify two separate original R2026b evaluations per new V11 x/y case.

No access to the Rust forecast; no case is dropped or averaged. Failure means
the genuine original MATLAB oracle is not self-consistent and cannot certify.
"""
import hashlib,json,pathlib
HERE=pathlib.Path(__file__).resolve().parent
INPUT_SHA='1144418910dc6a81ba3b98f9540fe914ac796d9a9bab25ce75f6c1ef2ace2f53'
FORECAST_SHA='c633624b9867e2a273fda4d0cd2fafa50ec6b749b3eba2fca9e896f1d0b8335f'
raw=HERE/'input.json'
result=HERE/'original_v11_480_raw_full_robustfit_clean.json'
assert hashlib.sha256(raw.read_bytes()).hexdigest()==INPUT_SHA
data=json.loads(result.read_bytes())
assert data['status']=='ORIGINAL_MATHWORKS_R2026B_FULL_ROBUSTFIT_480_V11_SOURCE_UNSEEN'
assert data['release']=='2026b' and data['case_count']==480 and data['original_repetitions']==2
assert data['new_input_sha256']==INPUT_SHA and data['pre_oracle_native_Rust_frozen_forecast_sha256']==FORECAST_SHA
assert data['original_unmodified'] is True and data['callback_noninterference_asserted'] is True
records=data['records'];cases=json.loads(raw.read_bytes())['cases']
assert len(records)==960 and len(cases)==480
keys=[k for k in records[0] if k not in {'original_rep'}]
for i,case in enumerate(cases):
    a,b=records[i],records[i+480]
    assert a['original_rep']==1 and b['original_rep']==2
    assert a['id']==b['id']==case['id'] and a['n']==b['n']==case['n']
    assert a['callback_does_not_perturb_original'] is True
    assert b['callback_does_not_perturb_original'] is True
    for key in keys:
        assert a[key]==b[key],f'Original R2026b self-consistency failed: case={i} field={key}'
    assert a['full_expected_original_callback_count']>=4
    assert a['full_expected_original_callback_count']<=53
    assert all(isinstance(h,str) and len(h)==16 for key in [
        'full_robust_s_hex','full_mad_s_hex','full_s_hex','ols_s_hex','std_y_hex'
        ] for h in [a[key]])
doc=dict(status='EXACT_GENUINE_ORIGINAL_R2026B_V11_480_X_TWO_PASS_NONINTERFERENCE',
    input_sha256=INPUT_SHA,
    frozen_private_rust_forecast_sha256=FORECAST_SHA,
    original_output_sha256=hashlib.sha256(result.read_bytes()).hexdigest(),
    checked_original_repetitions=2,checked_cases=480,
    all_fields_exact_original_repeat=True,
    callback_noninterference_asserted=True,
    source_to_native_rust_parity_not_tested_here=True)
dest=HERE/'original_v11_source_self_consistency.json'
dest.write_text(json.dumps(doc,sort_keys=True,indent=2)+'\n')
print('Genuine original MATLAB V11 self-consistency passed 480/480 complete all-field cases across 2 runs.')
