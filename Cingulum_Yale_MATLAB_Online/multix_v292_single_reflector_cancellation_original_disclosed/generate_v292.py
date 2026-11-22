#!/usr/bin/env python3
"""V292 genuine original-only SOURCE-DISCLOSED single active reflector
cancellation pairs, targeted at MATLAB multi-RHS implicit Householder
response reduction. Never an original-first-blind certificate.
"""
from pathlib import Path
from collections import Counter
import json,hashlib,random,math,struct

ROOT=Path(__file__).resolve().parent
SEED=202611220292
NS=(7,8,9,15,16,17,31,32,33,63,64,65)
MODES=('pair_cancel','lane_powers','alternating','boundary','tiny','head_cancel','sparse','noise')
def bits(x):
    assert math.isfinite(x)
    return struct.pack('>d',float(x)).hex()
def generate():
    data=[]
    for ni,n in enumerate(NS):
        for mi,mode in enumerate(MODES):
            rng=random.Random(SEED+ni*100003+mi*8999)
            # p=2, one active reflector: second predictor is e_2 and
            # X first predictor has zero in e_2 position. R is diagonal,
            # and original full A\B requires no nontrivial triangular
            # cross-coefficient update.
            v=[0.]*n
            v[0]=3.375
            for r in range(2,n-1):
                v[r]=(-1. if r%2 else 1.)*(0.87+0.24*rng.random())
            x2=[0.]*n;x2[1]=0.0625
            assert v[1]==0 and v[-1]==0
            y=[0.]*n
            y[1]=0.125
            terms=[0.]*n
            indices=list(range(2,n-1))
            for t,r in enumerate(indices):
                if mode=='pair_cancel':
                    terms[r]=((-1.)**t)*(2.**34)+(2.**-18)*rng.gauss(0.,1.)
                elif mode=='lane_powers':
                    terms[r]=((-1.)**t)*(2.**((r%13)-3))
                elif mode=='alternating':
                    terms[r]=((-1.)**t)*(0.5+0.0001220703125*r)
                elif mode=='boundary':
                    terms[r]=(2.**38)*((-1.)**t) if r in (2,3,7,8,15,16,31,32,63,64) else (2.**-8)*rng.gauss(0.,1.)
                elif mode=='tiny':
                    terms[r]=((-1.)**t)*(2.**-35)*(1. + rng.random())
                elif mode=='head_cancel':
                    terms[r]=((-1.)**t)*(2.**21)+rng.gauss(0.,1.)
                elif mode=='sparse':
                    terms[r]=((-1.)**t)*2.**25 if (r+1)%8 in (0,1) else 0.
                else:
                    terms[r]=rng.gauss(0.,2.)*(2.**((r%7)-3))
                y[r]=terms[r]/v[r]
            y[0]=(-sum(terms[r] for r in indices)+(2.**-26 if mode=='head_cancel' else rng.gauss(0.,1.)))
            y[-1]=0.
            assert all(math.isfinite(t) for t in y)
            data.append(dict(id=f'v292_{mode}_n{n}_seed{SEED+ni*100003+mi*8999}',
                n=n,p=2,mode=mode,a_colmajor_hex=[bits(t) for col in (v,x2) for t in col],
                b_hex=[bits(t) for t in y]))
    assert len(data)==96 and Counter(x['mode'] for x in data)==dict.fromkeys(MODES,12)
    out=dict(classification='V292_ORIGINAL_ONLY_SOURCE_DISCLOSED_SINGLE_REFLECTOR_CANCELLATION',
       seed=SEED,cohorts=96,matrix_lengths=list(NS),
       padding_counts=[0,7],rhs_widths=[1,2,3,4,5,6,7,8,9,12,16],
       original_MATLAB_numerical_values_consulted=False,
       native_Rust_forecast_used=False,
       new_first_original_blind_certificate=False,
       V252_first_original_blind_full17='FAIL',
       V263_first_original_blind_reduced='PASS_216_OF_216',
       V284_first_original_blind_full_length_single='PASS_1770_OF_1770',
       V12='SEALED',cases=data)
    b=(json.dumps(out,sort_keys=True,separators=(',',':'))+'\n').encode()
    dest=ROOT/'input.json';assert not dest.exists(),'frozen controlled input immutable'
    dest.write_bytes(b)
    h=hashlib.sha256(b).hexdigest()
    (ROOT/'input.sha256').write_text(h+'  input.json\n')
    print('V292 CONTROLLED SINGLE REFLECTOR CANCELLATION INPUT',h,len(data),'cases',MODES)
if __name__=='__main__':generate()
