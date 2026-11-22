#!/usr/bin/env python3
"""V306 genuinely NEW MATLAB ORIGINAL-FIRST-BLIND multi-RHS numeric challenge.

Only public synthetic matrices and 16 distinct/identical RHS columns are
frozen here. No Rust forecast, source MATLAB coefficients, or other oracle
result is available to this generator. Never overwrite the generated input.
"""
from pathlib import Path
from collections import Counter
import hashlib,json,math,random,struct

ROOT=Path(__file__).resolve().parent
SEED=202611220306
NS=(23,24,25,31,32,33,38,39,40,47,48,49,63,64,65,66,79,80,81,95,96,97,127,128,129)
WIDTHS=(1,2,3,4,5,6,7,8,9,12,16)
PADS=(0,1,7)
FAMILIES=('dense','correlated','cancellation','row_scaled')
GAMMA=(1.,1.,-1.,2.,0.125,4.,-0.5,0.75,1.5,0.0625,3.,-2.,0.25,1.25,-1.5,0.875)
def hx(x):
    assert math.isfinite(x)
    return struct.pack('>d',float(x)).hex()
def main():
    cases=[]
    for index in range(48):
        n=NS[(index*7+index//5)%len(NS)]
        p=3+(index*5%6)
        family=FAMILIES[index%4]
        seed=SEED+index*1000003
        rng=random.Random(seed)
        A=[[0.]*n for _ in range(p)]
        driver=[rng.gauss(0.,1.) for _ in range(n-1)]
        for j in range(p):
            for r in range(n-1):
                g=rng.gauss(0.,1.)
                if family=='dense':x=g
                elif family=='correlated':x=0.86*driver[r]+0.32*g+(0.12 if (j+r)%5==0 else 0.)
                elif family=='cancellation':x=(1. if (r+j)%2==0 else -1.)*(0.38+0.29*g)+0.19*driver[r]
                else:x=(2.**((r%9)-4))*(0.67*g+0.31*driver[r])
                A[j][r]=x+(0.08 if r==j else 0.)
        beta=[rng.gauss(0.,1.) for _ in range(p)]
        base=[sum(A[j][r]*beta[j] for j in range(p))+0.17*rng.gauss(0.,1.) for r in range(n-1)]
        base.append(0.)
        rhs=[]
        for col in range(16):
            if col in (0,1):
                values=base.copy()  # explicitly identical data in two output lanes
            else:
                values=[
                    GAMMA[col]*base[r]+0.15*rng.gauss(0.,1.)+0.05*A[col%p][r]
                    for r in range(n-1)
                ]
                values.append(0.)
            assert len(values)==n and values[-1]==0.
            rhs.append(values)
        assert all(x[-1]==0. for x in A)
        cases.append({
           'id':f'v306_{family}_n{n}_p{p}_seed{seed}',
           'n':n,'p':p,'family':family,
           'a_colmajor_hex':[hx(x) for col in A for x in col],
           'rhs16_colmajor_hex':[hx(x) for col in rhs for x in col],
        })
    assert len(cases)==48 and len(set(c['id'] for c in cases))==48
    assert Counter(x['p'] for x in cases)==dict.fromkeys(range(3,9),8)
    assert Counter(x['family'] for x in cases)==dict.fromkeys(FAMILIES,12)
    assert all(len(c['rhs16_colmajor_hex'])==16*c['n'] for c in cases)
    obj={
      'classification':'V306_NEW_SOURCE_UNSEEN_GENUINE_MATLAB_FULL_LENGTH_MULTI_RHS_MLDIVIDE',
      'seed':SEED,'cohorts':48,'max_RHS_columns':16,
      'RHS_matrix_widths':list(WIDTHS),'padding_counts':list(PADS),
      'source_MATLAB_numerical_results_consulted':False,
      'Rust_binary64_forecast_supplied_to_original':False,
      'first_original_blind_certificate_candidate':True,
      'historical_V252_first_blind_full17':'FAIL',
      'historical_V263_first_blind_reduced':'PASS_216_OF_216',
      'historical_V284_first_blind_full_length_single':'PASS_1770_OF_1770',
      'universal_V12':'SEALED',
      'cases':cases,
    }
    raw=(json.dumps(obj,sort_keys=True,separators=(',',':'))+'\n').encode()
    dst=ROOT/'input.json'
    assert not dst.exists(),'fail closed: original-first-blind matrix input must never be overwritten'
    dst.write_bytes(raw)
    sh=hashlib.sha256(raw).hexdigest()
    (ROOT/'input.sha256').write_text(sh+'  input.json\n')
    print('V306 FIRST ORIGINAL BLIND RAW FROZEN',sh,'cases',len(cases),
      'comparison_count',sum(c['p'] for c in cases)*sum(WIDTHS)*len(PADS))
if __name__=='__main__':main()
