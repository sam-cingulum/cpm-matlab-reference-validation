#!/usr/bin/env python3
"""Fail-closed same-runner binary64 R/h and genuine QR reflector buffer verification."""
import hashlib
import json
import os
import pathlib
import re
import struct

P = pathlib.Path(__file__).resolve().parent
clean = P / 'qr_control_v5_clean.json'
wrapped = P / 'qr_control_v5_captured.json'
capture = P / 'matlab_qr_capture_buffers.log'
counts = P / 'matlab_qr_capture_calls.log'
summary = {'workflow_run': os.environ.get('GITHUB_RUN_ID'),
           'capture_action_outcome': os.environ.get('CAPTURE_ACTION_OUTCOME'),
           'clean_exists':clean.exists(), 'captured_exists':wrapped.exists(),
           'capture_log_exists':capture.exists()}
if clean.exists() and wrapped.exists():
    ba, bb = clean.read_bytes(), wrapped.read_bytes()
    a, b = json.loads(ba)['records'], json.loads(bb)['records']
    assert len(a) == len(b) == 18
    summary['clean_sha256'] = hashlib.sha256(ba).hexdigest()
    summary['captured_sha256'] = hashlib.sha256(bb).hexdigest()
    keys = ('id','iteration','R_hex','source_R_hex','source_h_hex','pivot')
    summary['mismatched_records'] = {k:sum(x[k]!=y[k] for x,y in zip(a,b)) for k in keys}
    summary['bitwise_equal'] = not any(summary['mismatched_records'].values())
input_path=P.parent.parent/'robustfit_raw_full_source_unseen_v1'/'input.json'
assert hashlib.sha256(input_path.read_bytes()).hexdigest()=='36f70d7cfd31da808f4c5f61f1127e292597097287a21248782723436f26fa1b'
src=json.loads(input_path.read_text())
selected_indices=(0,1,6,12,23,47)
known={tuple(f'{struct.unpack("<Q",struct.pack("<d",float(z)))[0]:016x}' for z in src['cases'][i]['x']):src['cases'][i]['id'] for i in selected_indices}
matched={}; unmatched=0; ev_count=0; overflows=[]
if capture.exists():
    for line in capture.read_text().splitlines():
        if line.startswith('QR_BUFFER_SUMMARY\t'):
            match=re.search(r'overflow=(\d+)',line)
            if match:overflows.append(int(match.group(1)))
        elif line.startswith('QR_BUFFER_EVENT\t'):
            ev_count+=1
            fields=dict(x.split('=',1) for x in line.split('\t')[1:] if '=' in x)
            m=int(fields['m']); n=int(fields['n'])
            assert m in (29,35,71) and n==2
            inp=fields['A_IN'].split(','); out=fields['A_OUT'].split(',')
            assert len(inp)==len(out)==m*2
            assert all(x=='3ff0000000000000' for x in inp[:m])
            assert len(fields['tau'].split(','))==2
            assert fields['info']=='0'
            case_id=known.get(tuple(inp[m:]))
            if case_id:matched[case_id]=matched.get(case_id,0)+1
            else:unmatched+=1
summary['buffer_events']=ev_count
summary['matching_original_raw_input_cases']=matched
summary['unmatched_buffer_events']=unmatched
summary['capture_overflows']=overflows
if counts.exists():
    nonzero=[]
    for line in counts.read_text().splitlines():
        r=re.search(r'exe=(.*?)\tname=(.*?)\tcount=(\d+)$',line)
        if r and int(r.group(3)):
            nonzero.append({'exe':r.group(1),'name':r.group(2),'count':int(r.group(3))})
    summary['nonzero_real_function_counts']=nonzero
(P/'qr_buffer_v2_summary.json').write_text(json.dumps(summary,indent=2,sort_keys=True))
print('QR_BUFFER_V2_RESULT',json.dumps(summary,sort_keys=True))
assert clean.exists() and wrapped.exists() and summary['bitwise_equal'],'NUMERICAL_PARITY_FAILED'
assert summary['capture_action_outcome']=='success','MATLAB_PROCESS_FAILED'
assert ev_count>0,'NO_PRIVATE_QR_BUFFERS_OBSERVED'
assert overflows and not any(overflows),'BUFFER_RING_OVERFLOW'
assert sum(matched.values())>0,'NO_EXACT_RAW_SYNTHETIC_CASE_MATCH'
