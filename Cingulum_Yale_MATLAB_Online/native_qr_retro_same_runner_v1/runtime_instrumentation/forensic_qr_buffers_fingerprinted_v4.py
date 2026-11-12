#!/usr/bin/env python3
"""Verify permanently archived source-disclosed MathWorks 48-case QR reflector state."""
import collections,hashlib,json,pathlib,struct
P=pathlib.Path(__file__).resolve().parent
F=P/'reflector_capture_fingerprinted_43237581220'
source=P.parent.parent/'robustfit_raw_full_source_unseen_v1'/'input.json'
assert hashlib.sha256(source.read_bytes()).hexdigest()=='36f70d7cfd31da808f4c5f61f1127e292597097287a21248782723436f26fa1b'
cases=json.loads(source.read_bytes())['cases'];assert len(cases)==48
hex_x=lambda values:tuple(f'{struct.unpack("<Q",struct.pack("<d",float(x)))[0]:016x}' for x in values)
by_x={hex_x(c['x']):c['id'] for c in cases}
raw_a=(F/'qr_control_v6_clean.json').read_bytes();raw_b=(F/'qr_control_v6_captured.json').read_bytes()
assert hashlib.sha256(raw_a).hexdigest()==hashlib.sha256(raw_b).hexdigest()=='d059026575c68ea7b8e879157226e316f4eca65c8590e5ea09176ace44854a97'
a=json.loads(raw_a)['records'];b=json.loads(raw_b)['records'];assert len(a)==len(b)==144
assert all({k:v[k] for k in ('id','iteration','R_hex','source_R_hex','source_h_hex','pivot')}=={k:w[k] for k in ('id','iteration','R_hex','source_R_hex','source_h_hex','pivot')} for v,w in zip(a,b))
refs={}
for r in a:
 datum=(r['R_hex'],r['source_R_hex'],r['source_h_hex'],r['pivot'])
 if r['id'] in refs:assert refs[r['id']]==datum
 else:refs[r['id']]=datum
assert len(refs)==48
out=collections.defaultdict(list);n=0;overflow=0
for line in (F/'matlab_qr_capture_buffers_all48.log').read_text().splitlines():
 if line.startswith('QR_BUFFER_SUMMARY\t'):
  o=dict(x.split('=',1) for x in line.split('\t')[1:] if '=' in x)
  overflow+=int(o['overflow'])
 elif line.startswith('QR_BUFFER_EVENT\t'):
  n+=1
  d=dict(x.split('=',1) for x in line.split('\t')[1:] if '=' in x)
  m=int(d['m']);x=d['A_IN'].split(',');z=d['A_OUT'].split(',')
  assert len(x)==len(z)==2*m and all(t=='3ff0000000000000' for t in x[:m])
  ident=by_x.get(tuple(x[m:]));assert ident,('INPUT_NOT_ORIGINAL',d['seq'])
  qr,pivot=refs[ident][0],refs[ident][3]
  assert [z[0],'0000000000000000',z[m],z[m+1]]==qr
  assert [int(d['jpvt_first']),int(d['jpvt_second'])]==pivot and int(d['jpvt_abi'])==64
  assert d['info']=='0' and len(d['tau'].split(','))==2
  out[ident].append({'a_out_sha256':hashlib.sha256(','.join(z).encode()).hexdigest(),
                      'tau':d['tau'],'pivot':pivot,'R':qr,'m':m})
assert n==288 and overflow==0 and len(out)==48
index={}
for ident,r in sorted(out.items()):
 assert len(r)==6 and all(x==r[0] for x in r),('PRIVATE_QR_NONDETERMINISM',ident)
 index[ident]={**r[0], 'exact_snapshots':6}
report={'classification':'RETROSPECTIVE_HISTORICAL_SOURCE_DISCLOSED_ONLY',
 'matlab_github_run_id':'43237581220','original_synthetic_input_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),
 'clean_and_instrumented_matlab_output_sha256':hashlib.sha256(raw_a).hexdigest(),
 'full_private_qr_snapshots':n,'all_48_matched_source_input':True,'full_private_reflector_repeatability':True,
 'all_private_pivots_64bit_verified':True,'complete_R_h_pairwise_identical_across_144_records':True,
 'cases':index}
(F/'forensic_qr_buffers_fingerprinted_v4.json').write_text(json.dumps(report,indent=2,sort_keys=True)+'\n')
print('ALL48_ORIGINAL_MATHWORKS_HOUSEHOLDER_FORENSICS_PASS cases=48 private_snapshots=288 control_records=144 exact_source_inputs=48 exact_source_R=288 exact_pivots=288 all_tau_and_full_A_stable=48 overflow=0')
