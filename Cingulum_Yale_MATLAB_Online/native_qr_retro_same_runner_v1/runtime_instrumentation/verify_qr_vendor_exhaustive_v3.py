#!/usr/bin/env python3
"""Strict genuine MATLAB source noninterference and complete ordered three-term GEMV gate."""
import collections,hashlib,json,os,pathlib,struct
P=pathlib.Path(__file__).resolve().parent
I=P.parent.parent/'robustfit_raw_full_source_unseen_v1'/'input.json'
assert hashlib.sha256(I.read_bytes()).hexdigest()=='36f70d7cfd31da808f4c5f61f1127e292597097287a21248782723436f26fa1b'
rows=json.loads(I.read_bytes())['cases'];assert len(rows)==48
bits=lambda v:f'{struct.unpack("<Q",struct.pack("<d",float(v)))[0]:016x}'
by_x={tuple(bits(z) for z in c['x']):c['id'] for c in rows}
assert len(by_x)==48
clean=P/'qr_vendor_exhaustive_clean.json';traced=P/'qr_vendor_exhaustive_traced.json'
second=P/'qr_vendor_exhaustive_second.log';binary=P/'qr_vendor_exhaustive_three_terms.bin';summary=P/'qr_vendor_exhaustive_capture.summary'
s={'run_id':os.environ.get('GITHUB_RUN_ID'),'source_trace_outcome':os.environ.get('TRACE_OUTCOME')}
a,b=clean.read_bytes(),traced.read_bytes();aa=json.loads(a)['records'];bb=json.loads(b)['records'];assert len(aa)==len(bb)==144
s['clean_sha256']=hashlib.sha256(a).hexdigest();s['traced_sha256']=hashlib.sha256(b).hexdigest()
s['mismatched_original_records']={k:sum(x[k]!=y[k] for x,y in zip(aa,bb)) for k in ('id','iteration','R_hex','source_R_hex','source_h_hex','pivot')}
s['original_source_bitwise_exact']=not any(s['mismatched_original_records'].values())
assert s['original_source_bitwise_exact'] and s['source_trace_outcome']=='success','ORIGINAL_MATHWORKS_R_H_GATE_FAILED'
ref={}
for z in aa:
 val=(z['R_hex'],z['source_R_hex'],z['source_h_hex'],z['pivot'])
 if z['id'] in ref:assert ref[z['id']]==val,('MATLAB_REPEAT_R_H_DRIFT',z['id'])
 else:ref[z['id']]=val
assert len(ref)==48
observed=collections.defaultdict(list);logs=[]
for line in second.read_text().splitlines():
 if line.startswith('QR_VENDOR_SECOND_SUMMARY\t'):
  logs.append(dict(x.split('=',1) for x in line.split('\t')[1:] if '=' in x))
 if not line.startswith('QR_VENDOR_SECOND_EVENT\t'):continue
 d=dict(x.split('=',1) for x in line.split('\t')[1:] if '=' in x)
 case=by_x.get(tuple(d['X_HEX'].split(',')))
 assert case and int(d['info'])==0
 assert d['original_r12']==ref[case][0][2]
 assert list(map(int,d['pivot'].split(',')))==ref[case][3]
 assert d['vendor_dlarf_r12']==d['vendor_dgemv_r12']==d['original_r12'],('VENDOR_GEMV_NOT_ORIGINAL',case)
 observed[case].append(d)
assert len(observed)==48 and all(len(v)==6 and all(x==v[0] for x in v) for v in observed.values())
assert logs and all(int(d['overflow'])==0 for d in logs)
s['original_vendor_qr_events']=sum(map(len,observed.values()))
blob=binary.read_bytes();assert blob[:8]==b'QR3BIN01','UNKNOWN_BINARY_PROVENANCE'
count=int.from_bytes(blob[8:12],'little')
assert count==733194 and len(blob)==12+5*count,('INCOMPLETE_EXHAUSTIVE_CAPTURE',count,len(blob))
s['vendor_3term_sha256']=hashlib.sha256(blob).hexdigest()
obs_by_n=collections.Counter();one_by_n=collections.Counter();zero_by_n=collections.Counter();offset=12
for n in (29,35,43,44,57,71):
 for small in range(n):
  for plus in range(n):
   if plus==small:continue
   for minus in range(n):
    if minus==small or minus==plus:continue
    actual=tuple(blob[offset:offset+5]);offset+=5
    assert actual[:4]==(n,plus,minus,small),('MISSING_OR_OUT_OF_ORDER_VENDOR_TRIPLE',actual,n,plus,minus,small)
    assert actual[4] in (0,1),('UNEXPECTED_VENDOR_3TERM_VALUE',actual)
    obs_by_n[n]+=1
    if actual[4]==1:one_by_n[n]+=1
    else:zero_by_n[n]+=1
assert offset==len(blob) and sum(obs_by_n.values())==count
ex=summary.read_text().strip().splitlines()
assert len(ex)==1 and ex[0].startswith('QR_VENDOR_MICRO_EXHAUSTIVE_SUMMARY\t')
d=dict(x.split('=',1) for x in ex[0].split('\t')[1:] if '=' in x)
assert int(d['events'])==count and int(d['overflow'])==0 and int(d['repeat_mismatches'])==0 and int(d['unexpected'])==0 and int(d['shapes'])==6 and int(d['record_bytes'])==5
s.update({'exhaustive_triple_count':count,'expected_triples_by_n':dict(obs_by_n),'outcome_ones_by_n':dict(one_by_n),'outcome_zeros_by_n':dict(zero_by_n),'original_result_stable':'all 48 cases x 3 repeats x public QR+robustfit','vendor_DGEMV_R12_exact':'48/48','all_vendor_three_term_inputs_and_repeats_stable':True})
(P/'qr_vendor_exhaustive_verdict.json').write_text(json.dumps(s,indent=2,sort_keys=True)+'\n')
print('EXHAUSTIVE_MATLAB_VENDOR_DGEMV_PASS',json.dumps(s,sort_keys=True))
