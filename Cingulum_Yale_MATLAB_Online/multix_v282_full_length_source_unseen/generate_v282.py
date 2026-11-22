#!/usr/bin/env python3
"""Freeze fresh original-first-blind full-length MATLAB mldivide matrices.

Generator has NO MATLAB numeric output or Rust prediction dependencies.
Never edit the 64 inputs/seed after source-free Rust SHA preoracle freeze.
"""
import hashlib
import json
import math
from pathlib import Path
import random
import struct

ROOT=Path(__file__).resolve().parent
SEED=202611220282
NS=(23,24,25,31,32,33,38,39,40,47,48,49,63,64,65,66,79,80,81,95,96,97,127,128,129)
PADDING=(0,1,6,7,16)
def bithex(v):
    assert math.isfinite(v)
    return struct.pack('>d',float(v)).hex()
def main():
    cases=[]
    for index in range(64):
        n=NS[(index*7+index//5)%len(NS)]
        p=3+(index*5%6)
        family=('dense','correlated','cancellation','row_scaled')[index%4]
        seed=SEED+index*1000003
        rng=random.Random(seed)
        a=[[0.]*n for _ in range(p)]
        driver=[rng.gauss(0.,1.) for _ in range(n-1)]
        for j in range(p):
            for r in range(n-1):
                g=rng.gauss(0.,1.)
                if family=='dense':
                    x=g
                elif family=='correlated':
                    x=0.86*driver[r]+0.32*g+(0.12 if (j+r)%5==0 else 0.)
                elif family=='cancellation':
                    x=(1. if (r+j)%2==0 else -1.)*(0.38+0.29*g)
                    x+=0.19*driver[r]
                else:
                    x=(2.**((r%9)-4))*(0.67*g+0.31*driver[r])
                a[j][r]=x+(0.08 if r==j else 0.)
        weights=[rng.gauss(0.,1.) for _ in range(p)]
        y=[sum(a[j][r]*weights[j] for j in range(p))+0.17*rng.gauss(0.,1.) for r in range(n-1)]
        y.append(0.)
        assert len(y)==n and all(col[-1]==0. for col in a)
        cases.append({
            'id':f'v282_{family}_n{n}_p{p}_seed{seed}',
            'n':n,'p':p,'family':family,
            'a_colmajor_hex':[bithex(x) for col in a for x in col],
            'b_hex':[bithex(x) for x in y],
        })
    assert len(cases)==64 and len(set(c['id'] for c in cases))==64
    assert set(c['p'] for c in cases)==set(range(3,9))
    assert set(c['family'] for c in cases)=={'dense','correlated','cancellation','row_scaled'}
    obj={
      'classification':'CINGULUM_V282_NEW_SOURCE_UNSEEN_FULL_LENGTH_ZERO_PADDED_MLDIVIDE',
      'seed':SEED,'cohorts':64,
      'source_original_MATLAB_numeric_results_consulted':False,
      'predicted_full_length_original_coefficients_disclosed_to_MATLAB_runner':False,
      'first_original_blind_V252_verdict_unchanged':'FAIL',
      'historical_reduced_V263_first_original_blind':'PASS_216_OF_216',
      'comprehensive_V12':'SEALED',
      'padding_counts':list(PADDING),
      'matrix_families':['dense','correlated','cancellation','row_scaled'],
      'new_source_unseen_full_length_certification_candidate':True,
      'cases':cases,
    }
    dest=ROOT/'input.json'
    assert not dest.exists(),'fail closed: never overwrite immutable original-first-blind input'
    raw=(json.dumps(obj,sort_keys=True,separators=(',',':'))+'\n').encode()
    dest.write_bytes(raw)
    sha=hashlib.sha256(raw).hexdigest()
    (ROOT/'input.sha256').write_text(f'{sha}  input.json\n')
    print('V282 FRESH INPUT',sha,'cases',len(cases),'coefficients_per_padding',sum(c['p'] for c in cases),'p',[c['p'] for c in cases[:8]])
if __name__=='__main__':
    main()
