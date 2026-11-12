#!/usr/bin/env python3
"""Original MATLAB R/h exact gate and original DGEMV cancellation microkernel fingerprint."""
import collections,hashlib,json,math,os,pathlib,struct
P=pathlib.Path(__file__).resolve().parent
inp=P.parent.parent/'robustfit_raw_full_source_unseen_v1'/'input.json'
assert hashlib.sha256(inp.read_bytes()).hexdigest()=='36f70d7cfd31da808f4c5f61f1127e292597097287a21248782723436f26fa1b'
source=json.loads(inp.read_bytes())['cases'];assert len(source)==48
bits=lambda f:f'{struct.unpack("<Q",struct.pack("<d",float(f)))[0]:016x}'
by_x={tuple(bits(z) for z in c['x']):c['id'] for c in source}
assert len(by_x)==48
clean=P/'qr_vendor_micro_clean.json';trace=P/'qr_vendor_micro_traced.json'
log=P/'qr_vendor_micro_second.log';micro=P/'qr_vendor_micro_cancellation.log'
s={'run_id':os.getenv('GITHUB_RUN_ID'),'trace_outcome':os.getenv('TRACE_OUTCOME'),'clean_exists':clean.exists(),'trace_exists':trace.exists(),'log_exists':log.exists(),'micro_exists':micro.exists()}
reference={}
if clean.exists() and trace.exists():
 ca,cb=clean.read_bytes(),trace.read_bytes();a=json.loads(ca)['records'];b=json.loads(cb)['records'];assert len(a)==len(b)==144
 s['clean_sha256']=hashlib.sha256(ca).hexdigest();s['trace_sha256']=hashlib.sha256(cb).hexdigest()
 s['mismatched_original_records']={k:sum(x[k]!=y[k] for x,y in zip(a,b)) for k in ('id','iteration','R_hex','source_R_hex','source_h_hex','pivot')}
 s['bitwise_exact_original_mathworks']=not any(s['mismatched_original_records'].values())
 for row in a:
  item=(row['R_hex'],row['source_R_hex'],row['source_h_hex'],row['pivot'])
  if row['id'] in reference:assert reference[row['id']]==item
  else:reference[row['id']]=item
assert len(reference)==48 and s['bitwise_exact_original_mathworks'],'ORIGINAL_MATLAB_BITWISE_REFERENCE_MISMATCH'
assert s['trace_outcome']=='success','ORIGINAL_MATLAB_RUN_FAILED'
by_case=collections.defaultdict(list);summaries=[]
for line in log.read_text().splitlines():
 if line.startswith('QR_VENDOR_SECOND_SUMMARY\t'):
  summaries.append(dict(x.split('=',1) for x in line.split('\t')[1:] if '=' in x))
 if not line.startswith('QR_VENDOR_SECOND_EVENT\t'):continue
 d=dict(x.split('=',1) for x in line.split('\t')[1:] if '=' in x)
 key=tuple(d['X_HEX'].split(','));ident=by_x.get(key)
 assert ident and d['info']=='0'
 assert d['original_r12']==reference[ident][0][2]
 assert list(map(int,d['pivot'].split(',')))==reference[ident][3]
 by_case[ident].append(d)
assert len(by_case)==48 and all(len(v)==6 for v in by_case.values()),'ORIGINAL_QR_EVENT_COVERAGE_FAILURE'
assert summaries and all(int(d['overflow'])==0 for d in summaries)
for ident,v in by_case.items():
 assert all(r==v[0] for r in v),('ORIGINAL_VENDOR_DOT_REPEAT_DRIFT',ident)
 assert v[0]['vendor_dlarf_r12']==v[0]['vendor_dgemv_r12']==v[0]['original_r12'],('ORIGINAL_VENDOR_R12_NOT_EXACT',ident)
s['vendor_second_full_coverage']=sum(map(len,by_case.values()))
s['vendor_dlarf_r12_exact_cases']=48;s['vendor_dgemv_r12_exact_cases']=48
samples=collections.defaultdict(dict);summ=[]
for line in micro.read_text().splitlines():
 if line.startswith('QR_VENDOR_MICRO_SUMMARY\t'):
  summ.append(dict(x.split('=',1) for x in line.split('\t')[1:] if '=' in x))
 if not line.startswith('QR_VENDOR_MICRO_EVENT\t'):continue
 d=dict(x.split('=',1) for x in line.split('\t')[1:] if '=' in x)
 n,plus,minus,small=(int(d[k]) for k in ('n','plus','minus','small'))
 assert n in (29,35,43,44,57,71) and len({plus,minus,small})==3 and 0<=plus<minus<n
 assert small in (0,n//2,n-1)
 assert d['dot'] in ('0000000000000000','3ff0000000000000'),('UNEXPECTED_SYNTHETIC_GEMV_SUM',d)
 key=(small,plus,minus)
 assert key not in samples[n],('DUPLICATE_CANCELLATION_PROBE',n,key)
 samples[n][key]=d['dot']
assert len(summ)==1 and int(summ[0]['shapes'])==6 and int(summ[0]['overflow'])==int(summ[0]['repeat_mismatches'])==0
expected={n:3*math.comb(n-1,2) for n in (29,35,43,44,57,71)}
assert {n:len(v) for n,v in samples.items()}==expected,'MISSING_CANCELLATION_PROBES'
s['microprobe_sha256']=hashlib.sha256(micro.read_bytes()).hexdigest()
s['microprobe_events']=sum(map(len,samples.values()))
s['microprobe_counts_per_shape']=expected
s['microprobe_result_one_count']={str(n):sum(v=='3ff0000000000000' for v in pairs.values()) for n,pairs in samples.items()}
s['microprobe_result_zero_count']={str(n):sum(v=='0000000000000000' for v in pairs.values()) for n,pairs in samples.items()}
(P/'qr_vendor_micro_summary.json').write_text(json.dumps(s,indent=2,sort_keys=True)+'\n')
print('ORIGINAL_MATLAB_GEMV_CANCELLATION_FINGERPRINT_PASS',json.dumps(s,sort_keys=True))
