"""Boundary cases for the unchanged Yale predictor and behavior checks."""
import hashlib
import json
import math
from pathlib import Path
import random
import struct

def bits(x):
    return struct.pack(">d",x).hex()

def array(shape, values):
    return dict(shape=shape,hex=values)

rng=random.Random(701203)
cases=[]
for trial in range(4):
    n=(4,8,11,15)[trial]
    for mode in ("matrix","symmetric","later_asymmetric","asymmetric","rectangular","zero_rows",
                 "mixed","nan_diagonal","nan_pair","inf_pair","single_feature","mismatch","four_d",
                 "trailing_one","one_column","row_behavior","matrix_behavior","empty_features"):
        rows=4
        shape=[rows,rows,n]
        if mode in ("matrix","row_behavior","matrix_behavior"): shape=[4,n]
        if mode=="trailing_one": shape=[4,n,1,1]
        if mode=="single_feature": shape=[1,4,n]
        if mode=="four_d": shape=[4,4,n,2]
        if mode=="rectangular": shape=[4,3,n]
        if mode=="one_column": shape=[4,1,n]
        if mode=="empty_features": shape=[0,n]
        vals=[bits(rng.randint(-61,61)/16) for _ in range(math.prod(shape))]
        if len(shape)==3 and shape[:2]==[4,4]:
            for s in range(n):
                for j in range(rows):
                    for i in range(j):
                        vals[s*16+j*rows+i]=vals[s*16+i*rows+j]
            if mode=="later_asymmetric": vals[16+1]=bits(99.)
            if mode=="asymmetric": vals[1]=bits(98.)
            if mode=="nan_diagonal": vals[0]="7ff800000000001b"
            if mode=="nan_pair": vals[1]=vals[4]="fff800000000001a"
            if mode=="inf_pair": vals[1]=vals[4]=bits(float("-inf"))
            if mode in ("zero_rows","mixed"):
                for s in (0,n-1):
                    for j in range(4): vals[s*16+4*j+1]=bits(-0.)
                if mode=="mixed": vals[0]=bits(float("inf"));vals[16]="7ff8000000000015"
        if mode=="matrix":
            for j in range(n): vals[4*j+2]=bits(-0.)
        m=n+int(mode=="mismatch")
        ys=[1,m] if mode=="row_behavior" or trial%2 else [m,1]
        if mode=="matrix_behavior":ys=[m,2]
        if mode=="four_d": ys=[2,1]
        y=[bits(rng.randint(-12,12)/8) for _ in range(math.prod(ys))]
        y[0]=bits(-0.)
        cases.append(dict(id=f"{mode}_{trial}",request=dict(x=array(shape,vals),y=array(ys,y),
                            folds=(2,n+1,n,n+3)[trial])))
out=Path(__file__).with_name("input.json")
out.write_text(json.dumps(cases,separators=(",",":"))+"\n")
out.with_suffix(".sha256").write_text(hashlib.sha256(out.read_bytes()).hexdigest()+"  input.json\n")
