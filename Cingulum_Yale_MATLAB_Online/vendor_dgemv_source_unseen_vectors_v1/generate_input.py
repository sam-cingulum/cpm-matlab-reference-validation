#!/usr/bin/env python3
"""Freeze fully deterministic raw binary64 vendor DGEMV dot-product input.
Must commit this before running MathWorks source. Two independent native Rust
CPU-tree forecasts are sealed separately before original vendor execution.
"""
from pathlib import Path
import hashlib,random,struct
r=random.Random(202611130472)
ns=(16,17,20,23,24,25,28,29,30,31,32,33,34,35,36,40,41,43,44,45,47,48,55,56,57,58,63,64,65,69,70,71,72,73,80,95,96,97,111,128)
kinds=('baseline','scaled','alternating','offset','nearflat','spikes','powers','clustered','positive','negative','small','dynamic')
f=lambda x:struct.pack('>d',float(x)).hex()
rows=[]
for n in ns:
 for kind in kinds:
  xs=[];vs=[]
  for i in range(n):
   a=r.gauss(0,0.83);b=r.gauss(0,1.11)
   if kind=='baseline':x=a;v=b
   elif kind=='scaled':x=a*256.;v=b*.004
   elif kind=='alternating':x=a*((-1.)**i);v=b*((-1.)**(i+1))
   elif kind=='offset':x=a+2.5;v=b-1.5
   elif kind=='nearflat':x=a*1e-8+.95;v=b*1e-8+.67
   elif kind=='spikes':x=a+(25. if i==n//3 else 0.);v=b-(17. if i==n//2 else 0.)
   elif kind=='powers':x=a*(2.**(i%7));v=b*(2.**(-(i%6)))
   elif kind=='clustered':x=(1. if i%3 else -.9)+a/17;v=(-1. if i%4 else 1.)+b/21
   elif kind=='positive':x=abs(a)+1e-5;v=abs(b)+1e-5
   elif kind=='negative':x=-abs(a)-1e-6;v=abs(b)-0.8
   elif kind=='small':x=a*1e-5;v=b*1e-6
   else:x=a*(1e5 if i%5==0 else 1e-5);v=b*(1e-5 if i%7==0 else 1e5)
   xs.append(x);vs.append(v)
  rows.append((f'dgemv_unseen_{n}_{kind}_seed202611130472',n,[f(x) for x in vs],[f(x) for x in xs]))
assert len(rows)==480 and len({r[0] for r in rows})==480
p=Path(__file__).with_name('input.tsv')
p.write_text(''.join(f'{id}\t{n}\t{",".join(v)}\t{",".join(x)}\n' for id,n,v,x in rows))
print('FROZEN_INPUT',len(rows),len(ns),'SHA256',hashlib.sha256(p.read_bytes()).hexdigest())
