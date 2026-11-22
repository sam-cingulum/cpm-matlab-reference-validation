#!/usr/bin/env python3
"""V287: original-only SOURCE-DISCLOSED controlled Householder step geometry.

Intentionally no Rust predictions/original MATLAB outputs. This is original
numerical research, NOT an original-first-blind certification.
"""
from pathlib import Path
from collections import Counter
import random,math,json,hashlib,struct

ROOT=Path(__file__).resolve().parent
NS=(7,8,9,15,16,17,31,32,33,63,64,65)
PADS=(0,7)
WIDTHS=(1,2,3,4,5,6,7,8,9,12,16)
SEED=202611220287
SHAPES=(('single_one',1),('single_two',2),('single_three',3),
        ('double_two',2),('cancel_two',2),('cancel_three',3),
        ('dense_two',2),('dense_three',3))

def bits(x):
    assert math.isfinite(x)
    return struct.pack('>d',float(x)).hex()

def generate():
    out=[]
    for ni,n in enumerate(NS):
        for mode,p in SHAPES:
            seed=SEED+ni*100003+sum(ord(v) for v in mode)*101
            rng=random.Random(seed)
            v=[(((-1.)**r)*(1.+0.03*r)+0.0625*rng.gauss(0.,1.))
               for r in range(n-1)]
            v[0]=3.375
            v.append(0.)
            x=[v[:]]
            if mode.startswith('single_'):
                for j in range(1,p):
                    v[j]=0.
                    x[0][j]=0.
                    column=[0.]*n
                    column[j]=0.125/(j+1)
                    x.append(column)
            elif mode=='double_two':
                # First reflector has zero at the second column's isolated row;
                # second Householder vector then has exactly one nonzero tail.
                x[0][n-2]=0.
                col=[0.]*n
                col[n-2]=0.125
                x.append(col)
            elif mode.startswith('cancel_'):
                x=[[0.]*n for _ in range(p)]
                for j in range(p):
                    for r in range(n-1):
                        x[j][r]=((1. if (r+j)%2 else -1.)*
                                  (0.5+0.125*rng.gauss(0.,1.)))+0.25*rng.gauss(0.,1.)
                        if r==j:x[j][r]+=0.375
            else:
                x=[[0.]*n for _ in range(p)]
                for j in range(p):
                    for r in range(n-1):
                        x[j][r]=rng.gauss(0.,1.)+(0.375 if r==j else 0.)
            if mode.startswith('cancel_'):
                b=[(1. if r%2 else -1.)*2.**((r%11)-5)+
                   0.125*rng.gauss(0.,1.) for r in range(n-1)]
            else:
                beta=[rng.gauss(0.,1.) for _ in range(p)]
                b=[sum(x[j][r]*beta[j] for j in range(p))+
                   0.13125*rng.gauss(0.,1.) for r in range(n-1)]
            b.append(0.)
            assert all(c[-1]==0. for c in x) and b[-1]==0.
            assert len(x)==p and all(len(c)==n for c in x)
            out.append(dict(id=f'v287_{mode}_n{n}_p{p}_seed{seed}',
                n=n,p=p,mode=mode,
                a_colmajor_hex=[bits(t) for col in x for t in col],
                b_hex=[bits(t) for t in b]))
    assert len(out)==96 and len(set(v['id'] for v in out))==96
    assert Counter(x['mode'] for x in out)==dict.fromkeys((m for m,_ in SHAPES),12)
    payload=dict(
      classification='V287_ORIGINAL_ONLY_SOURCE_DISCLOSED_CONTROLLED_HOUSEHOLDER_STEP_GEOMETRY',
      seed=SEED,cohorts=96,
      matrix_lengths=list(NS),
      padding_counts=list(PADS),
      rhs_widths=list(WIDTHS),
      original_MATLAB_numerical_values_consulted=False,
      native_Rust_forecast_used=False,
      new_first_original_blind_certificate=False,
      V252_first_original_blind_full17='FAIL',
      V263_first_original_blind_reduced='PASS_216_OF_216',
      V284_first_original_blind_full_length_single='PASS_1770_OF_1770',
      V12='SEALED',cases=out
    )
    b=(json.dumps(payload,sort_keys=True,separators=(',',':'))+'\n').encode()
    dst=ROOT/'input.json'
    assert not dst.exists(),'never overwrite source-original numerical probe'
    dst.write_bytes(b)
    h=hashlib.sha256(b).hexdigest()
    (ROOT/'input.sha256').write_text(h+'  input.json\n')
    print('V287 FROZEN CONTROLLED ORIGINAL INPUT',h,'cases',len(out),
          'n',NS,'p',Counter(v['p'] for v in out))
if __name__=='__main__':generate()
