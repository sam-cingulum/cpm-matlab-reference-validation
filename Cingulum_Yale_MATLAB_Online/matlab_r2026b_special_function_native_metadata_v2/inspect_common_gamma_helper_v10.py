#!/usr/bin/env python3
"""Bounded static architecture of shared gamma helper, on authorized R2026b only.

Produces metadata counts and branch exits, never original code, constants,
operand data or numerical outputs. An original-compatible pure-Rust gamma
implementation is neither present nor certified by this investigation.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import pathlib
from inspect_gamma_beta_entry_cfg_v7 import audit_cfg

LIB_SHA = "625bc659a790963d52dca039c66bcbde68c319caba37f89b85dd977c6a3be848"

def sha(path):
    h=hashlib.sha256()
    with path.open('rb') as f:
        for chunk in iter(lambda:f.read(1024*1024),b''):
            h.update(chunk)
    return h.hexdigest()

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument('matlab_root')
    ap.add_argument('output_json')
    args=ap.parse_args()
    lib=pathlib.Path(args.matlab_root)/'bin/glnxa64/libmwmathspec.so'
    assert lib.is_file() and sha(lib)==LIB_SHA,'original runtime SHA mismatch'
    # Inspect just the direct-call helper identified independently in original
    # V7 gamma and beta CFGs. The bounded window is a tool limit, not a
    # deliberately guessed function length.
    entry=0x632e0
    result=audit_cfg(lib,'shared_gamma_beta_internal_helper',entry,entry+0x2800)
    report={
        'classification':'ORIGINAL_R2026B_SHA_LOCKED_GAMMA_SHARED_HELPER_STATIC_CFG_V10',
        'original_library_sha256':LIB_SHA,
        'helper_called_from_original_gamma_and_beta':True,
        'helper_identity_mathematical_function':'UNPROVEN',
        'source_unseen_V12':'NOT_GENERATED',
        'pure_Rust_gamma_beta_bit_parity':'NOT_CERTIFIED',
        'vendor_source_disassembly_constants_or_values_published':False,
        'helper_cfg':result,
        'scope_limit':'Direct branch topology only; calls stepped over and indirects unresolved. A closed static graph does not establish mathematical operation order or correctness.',
    }
    out=pathlib.Path(args.output_json)
    out.parent.mkdir(parents=True,exist_ok=True)
    out.write_text(json.dumps(report,sort_keys=True,indent=2)+'\n')
    print('SHARED_GAMMA_HELPER_CFG_REACHABLE',result['reachable_instructions_static'])
    print('RETURNS',len(result['reachable_return_offsets']))
    print('BRANCHES',result['reachability_counts'].get('conditional_branches',0))
    print('EXITS',result['escape_counts'],'CALLS',result['direct_call_target_site_counts'])
    print('REPORT_SHA256',sha(out))

if __name__=='__main__':main()
