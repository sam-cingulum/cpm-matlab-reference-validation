#!/usr/bin/env python3
"""Construct exact binary64 input to study genuine MATLAB public Q' * y.

This is an explicit source-API microprobe, NOT a Rust parity certification.
Cancellations isolate the summation tree from multiplication/FMA rounding.
"""
import hashlib,json,random,struct,math
from pathlib import Path
seed=202611136333
rng=random.Random(seed)
lengths=(9,10,11,12,15,16,17,18,23,24,25,28,31,32,33,39,40,47,48,55,56,63,64,65,71,97,128)
F=lambda v:struct.pack('>d',float(v)).hex()
records=[]
for n in lengths:
    pairs=list(dict.fromkeys(tuple(sorted(pair)) for pair in [(0,1),(0,n-1),(1,n-2),(n//4,3*n//4),(n//2,n//2+1),(n//3,n//3+1)]))
    if n<=24:ks=list(range(n))
    else:ks=sorted(set([0,1,2,3,4,5,6,7,n//4-1,n//4,n//4+1,n//2-1,n//2,n//2+1,3*n//4-1,3*n//4,3*n//4+1,n-8,n-7,n-6,n-5,n-4,n-3,n-2,n-1]))
    for a,b in pairs:
        for k in ks:
            if k in (a,b):continue
            q1=[0.]*n;q2=[0.]*n;q1[a]=2.**54;q1[b]=-(2.**54);q1[k]=1.
            q2[a]=-(2.**54);q2[b]=2.**54;q2[k]=1.
            records.append({'id':f'tree_n{n}_a{a}_b{b}_k{k}','n':n,'scenario':'cancellation_tree','Q_hex':[F(z) for z in q1+q2],'y_hex':[F(1.)]*n,'additive_terms':[a,b,k]})
    for j in range(20):
        q1=[];q2=[];y=[]
        for i in range(n):
            scale=(2.**(i%7-3)) if j%3==0 else 1.
            q1.append(rng.gauss(0.,1.)*scale);q2.append(rng.gauss(0.,1.)*scale)
            y.append(rng.gauss(0.,1.))
        records.append({'id':f'product_n{n}_j{j}','n':n,'scenario':'random_product','Q_hex':[F(z) for z in q1+q2],'y_hex':[F(z) for z in y]})
assert len({r['id'] for r in records})==len(records)
assert all(len(r['Q_hex'])==2*r['n'] and len(r['y_hex'])==r['n'] and all(len(t)==16 for t in r['Q_hex']+r['y_hex']) for r in records)
obj={'schema':'AUTHENTIC_ORIGINAL_MATHWORKS_R2026B_BLAS_GEMV_Qtranspose_Y_REDUCTION_TREE_MICROPROBE_V1','seed':seed,'matlab_source_code_unmodified':True,'source_blind_numeric_candidate_forecast_frozen':False,'lengths':lengths,'cases':records}
p=Path(__file__).with_name('input.json');p.write_text(json.dumps(obj,separators=(',',':'),sort_keys=True)+'\n')
print('ORIGINAL_MATHWORKS_QY_MATRIX_KERNEL_MICROPROBE',len(records),'distinct length',len(lengths),'cancellations',sum(r['scenario']=='cancellation_tree' for r in records),'random',sum(r['scenario']=='random_product' for r in records),'original_input_sha256',hashlib.sha256(p.read_bytes()).hexdigest())
