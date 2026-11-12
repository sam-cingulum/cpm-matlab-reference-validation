"""Fail-closed original R2026b full-bit capture verifier (historical only)."""
import hashlib,json,re,struct,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
SRC=ROOT/'robustfit_raw_full_source_unseen_v1'
FILE=Path(sys.argv[1]) if len(sys.argv)>1 else Path(__file__).with_name('full_bit_capture_v1.json')
assert hashlib.sha256((SRC/'input.json').read_bytes()).hexdigest()=='36f70d7cfd31da808f4c5f61f1127e292597097287a21248782723436f26fa1b'
raw=json.loads((SRC/'input.json').read_bytes())['cases']
d=json.loads(FILE.read_bytes());assert d['release']=='2026b' and d['case_count']==48
assert d['not_prospective'] and d['source_original_unmodified']
assert d['private_qr_intermediates_not_observable'] and d['first_reflector_v_tau_reconstructed_not_internal']
assert len(d['records'])==len(raw)==48
H=re.compile(r'^[0-9a-fA-F]{16}$')
scalar=['first_alpha_hex','first_beta_hex','first_tau_reconstructed_hex','first_dot_builtin_hex','first_dot_matmul_hex','first_dot_sum_hex','first_dot_sequential_hex']
vector=['raw_x_hex','raw_y_hex','first_raw_hex','second_raw_hex','first_v_reconstructed_hex','first_dot_terms_hex','first_dot_prefix_sequential_hex','first_dot_prefix_cumsum_hex','transformed_matrix_hex','transformed_dot_hex','transformed_sum_hex','transformed_sequential_hex','transformed_left_hex','transformed_fused_hex','original_robustfit_h_hex']
Q=['public_pivot_Q_hex','public_nonpivot_Q_hex'];R=['original_robustfit_R_hex','public_pivot_R_hex','public_nonpivot_R_hex']
for row,orig in zip(d['records'],raw):
 n=row['n'];assert row['id']==orig['id'] and n==len(orig['x'])
 for key in scalar:assert isinstance(row[key],str) and H.fullmatch(row[key]),(row['id'],key)
 for key in vector+Q+R+['X_hex']:
  expect=2*n if key in Q+['X_hex'] else 4 if key in R else n
  assert len(row[key])==expect and all(H.fullmatch(v) for v in row[key]),(row['id'],key)
 for value,hexstr in zip(orig['x'],row['raw_x_hex']):
  assert struct.pack('>d',value).hex()==hexstr.lower(),(row['id'],'x transport')
 for value,hexstr in zip(orig['y'],row['raw_y_hex']):
  assert struct.pack('>d',value).hex()==hexstr.lower(),(row['id'],'y transport')
 assert row['source_equals_public_pivot_R']
 assert sorted(row['pivot'])==[1,2]
 assert row['first_v_reconstructed_hex'][0]=='3ff0000000000000'
print(json.dumps({'status':'GENUINE_MATLAB_FULL_BIT_CAPTURE_V1_PASS','source_disclosed':True,
                  'run_id':d['github_run_id'],'cases':48,'file_sha256':hashlib.sha256(FILE.read_bytes()).hexdigest()}))
