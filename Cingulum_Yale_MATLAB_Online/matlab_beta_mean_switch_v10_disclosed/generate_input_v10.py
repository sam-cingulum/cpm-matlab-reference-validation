#!/usr/bin/env python3
"""Prospectively precommitted V10 beta mean-tail switch falsification battery.

This is a new SOURCE-DISCLOSED scientific validation, not sealed V12.
No original MATLAB numeric output, historical failure IDs, patient data,
or per-case target rounding bits are used to generate the inputs.
"""
from __future__ import annotations
import hashlib
import json
import math
import random
import struct
from pathlib import Path
HERE=Path(__file__).resolve().parent
SCHEMA="CINGULUM_R2026B_BETA_MEAN_SWITCH_V10_SOURCE_DISCLOSED"
CLASS="SOURCE_DISCLOSED_NUMERICAL_BRANCH_MICROPROBE_NOT_SOURCE_UNSEEN"

def hx(x:float)->str:
    assert math.isfinite(x)
    return struct.pack(">d",x).hex()

def neighbors(x:float)->list[float]:
    return [math.nextafter(x,-math.inf),x,math.nextafter(x,math.inf)]

def main()->None:
    gvals=set()
    shapes_g=[.125,.25,.375,.75,1.25,2.25,3.75,5.75,8.25,9.25,11.25,
              16.25,24.5,32.5,49.5,64.5,83.5,112.5,127.5,150.5]
    for g in shapes_g:
        for x in neighbors(g):
            if 0<x<=169:gvals.add(x)
    gammas=[{"id":f"v10_gamma_{i:05d}","x_hex":hx(x)}
             for i,x in enumerate(sorted(gvals))]
    beta_set=set()
    primary_a=[.125,.25,.75,1.25,2.25,4.25,6.75,9.25,12.75,22.25,49.5,127.5]
    primary_b=[.125,.75,1.25,3.75,13.25,51.5,127.5]
    # New, source-independent parameter triples, not selected on exact
    # match/mismatch bits from historical genuine MATLAB.
    rng=random.Random(20261115)
    pairs={(a,b) for a in primary_a for b in primary_b}
    for _ in range(65):
        a=10**rng.uniform(-2,2.5)
        b=10**rng.uniform(-2,2.5)
        pairs.add((a,b))
    for a,b in sorted(pairs):
        mean=a/(a+b)
        nr=(a+1)/(a+b+2)
        for x in (
            neighbors(mean)+neighbors(nr)+
            [2.**-200,2.**-60,2.**-40, .0001,.02,.17,.25,.5,.7,.83,.98,
             1.-2.**-40,1.-2.**-50]
        ):
            if math.isfinite(x) and 0<x<1:
                beta_set.add((a,b,x))
    betas=[{"id":f"v10_beta_{i:05d}","a_hex":hx(a),"b_hex":hx(b),"x_hex":hx(x)}
            for i,(a,b,x) in enumerate(sorted(beta_set))]
    t_set=set()
    for nu in (4.,6.,8.,10.,12.,16.,18.,22.,24.,26.,28.,32.,36.,40.,48.,64.):
        root=math.sqrt(nu)
        for t in (0.,2.**-45,.1,.7,1.,root,math.nextafter(root,-math.inf),
                  math.nextafter(root,math.inf),-root,-.7,2*root,10.,1000.):
            t_set.add((nu,t))
    students=[{"id":f"v10_student_{i:05d}","nu_hex":hx(nu),"t_hex":hx(t)}
              for i,(nu,t) in enumerate(sorted(t_set))]
    result={
        "schema":SCHEMA,"classification":CLASS,
        "input_classification":"SOURCE_DISCLOSED_NEW_V10_NOT_V12",
        "source_unseen_V12":"NOT_GENERATED",
        "original_MATLAB_numeric_data_supplied":False,
        "gamma_count":len(gammas),"beta_count":len(betas),
        "student_count":len(students),
        "gamma":gammas,"beta":betas,"student":students
    }
    assert 55<=len(gammas)<=70
    assert 1500<=len(betas)<=3500
    assert 180<=len(students)<=250
    blob=(json.dumps(result,indent=2,sort_keys=True)+"\n").encode()
    digest=hashlib.sha256(blob).hexdigest()
    (HERE/"input.json").write_bytes(blob)
    (HERE/"input.sha256").write_text(f"{digest}  input.json\n")
    print(f"New prospective SOURCE-DISCLOSED V10: {len(gammas)} gamma, "
          f"{len(betas)} beta, {len(students)} Student-t; raw input SHA256 {digest}")

if __name__=="__main__":
    main()
