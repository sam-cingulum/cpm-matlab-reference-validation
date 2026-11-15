#!/usr/bin/env python3
"""Prospective, PUBLIC source-disclosed MATLAB R2026b numerical V7 inputs.

New input design, no historical original output, no patient/clinical data.
Freeze the SHA and runner in PUBLIC Git before any new original execution.
"""
from __future__ import annotations
import hashlib
import json
import math
import struct
from pathlib import Path

HERE=Path(__file__).resolve().parent
SCHEMA="CINGULUM_R2026B_GAMMA_BETA_BRANCH_PROBE_V7_SOURCE_DISCLOSED"
CLASS="SOURCE_DISCLOSED_NUMERICAL_BRANCH_MICROPROBE_NOT_SOURCE_UNSEEN"

def hx(v:float)->str:
    assert math.isfinite(v)
    return struct.pack(">d",v).hex()

def neighbors(x:float, n:int=1)->list[float]:
    values=[x]
    l=r=x
    for _ in range(n):
        l=math.nextafter(l,-math.inf)
        r=math.nextafter(r,math.inf)
        values.extend([l,r])
    return values

def main()->None:
    # Prospectively cover half-integer gamma breakpoints and fractional values
    # not selected from previously observed MathWorks output bits.
    gvals=set()
    anchors=[
      .125,.25,.375,.5,.625,.75,.875,.999,1.,1.125,1.25,1.5,1.75,2.,2.5,
      3.,3.5,4.,4.5,5.5,6.5,7.5,8.5,9.5,10.,10.5,11.,11.5,12.5,13.5,
      14.5,15.5,16.5,17.5,18.5,19.5,20.5,21.5,22.5,23.5,24.5,
      25.5,27.5,29.5,30.5,32.5,35.5,40.5,48.5,50.5,60.5
    ]
    fractions=[math.pi/2,math.e,1/3,2/3,1/7,4/7,
               1.00001,2.718281828,3.14159265,5.125,7.375,11.25,20.75]
    for x in anchors+fractions:
        for y in neighbors(x,2):
            if 0<y<=61:gvals.add(y)
    gammas=[{"id":f"branch_v7_gamma_{i:05d}","x_hex":hx(v)}
            for i,v in enumerate(sorted(gvals))]
    # Boundary neighbourhoods of both mean-based and NR-fraction switch
    # rules, with extra Student-t half-integer shapes and hard survival tails.
    beta_values=set()
    a_shapes=[.5,1.,1.5,2.5,3.5,4.5,6.5,7.5,10.5,11.5,12.5,20.5]
    b_shapes=[.5,1.,1.5,2.,3.]
    for a in a_shapes:
        for b in b_shapes:
            mass=a/(a+b)
            nr=(a+1.)/(a+b+2.)
            xs=(
                neighbors(mass,1)+neighbors(nr,1)+
                [2.**-48,2.**-16,.02,.2,.5,.8,.98,
                 1.-2.**-16,1.-2.**-48]
            )
            for x in xs:
                if 0<x<1:beta_values.add((a,b,x))
    betas=[{"id":f"branch_v7_beta_{i:05d}",
            "a_hex":hx(a),"b_hex":hx(b),"x_hex":hx(x)}
            for i,(a,b,x) in enumerate(sorted(beta_values))]
    # New source-disclosed Student-t values, including dfe outside the
    # previous 480-case source-unseen V11 and previous V2 probe.
    student_values=set()
    for nu in [3.,5.,7.,9.,11.,13.,15.,17.,19.,21.,23.,25.,29.,33.,37.]:
        s=math.sqrt(nu)
        ts=[
            0.,2.**-42,.03,.125,.3,.7,1.,2.,3.,s,
            math.nextafter(s,-math.inf),
            math.nextafter(s,math.inf),
            -s,-math.nextafter(s,-math.inf),-math.nextafter(s,math.inf),
            2*s,8*s,24.,150.,1e4
        ]
        for x in ts:student_values.add((nu,x))
    students=[{"id":f"branch_v7_student_{i:05d}",
               "nu_hex":hx(nu),"t_hex":hx(t)}
              for i,(nu,t) in enumerate(sorted(student_values))]
    result={
        "schema":SCHEMA,"classification":CLASS,
        "input_classification":"PUBLIC_SOURCE_DISCLOSED_NOT_NEW_SOURCE_UNSEEN",
        "original_MATLAB_numeric_data_supplied":False,
        "source_unseen_V12":"NOT_GENERATED",
        "gamma_count":len(gammas),
        "beta_count":len(betas),
        "student_count":len(students),
        "gamma":gammas,"beta":betas,"student":students
    }
    assert 250<=len(gammas)<400
    assert 500<=len(betas)<1000
    assert 250<=len(students)<350
    blob=(json.dumps(result,indent=2,sort_keys=True)+"\n").encode()
    (HERE/"input.json").write_bytes(blob)
    digest=hashlib.sha256(blob).hexdigest()
    (HERE/"input.sha256").write_text(f"{digest}  input.json\n")
    print(f"V7 deliberately disclosed grid: gamma={len(gammas)}, beta={len(betas)}, "
          f"Student-t={len(students)}; input sha256={digest}")

if __name__=="__main__":
    main()
