#!/usr/bin/env python3
"""Fully deterministic source-unseen QR parity inputs. Freeze before MATLAB execution."""
import hashlib
import json
import random
from pathlib import Path
r=random.Random(202611130173)
rows=[]
for n in [29,35,43,44,57,71]:
 for scenario in range(12):
  kind=['baseline','outlier','rescaled','nearflat','offset','small','wide','trend','alternating','skewed','clustered','exponential'][scenario]
  x=[]
  for i in range(n):
   a=r.gauss(0,0.7)
   if kind=='baseline': v=a
   elif kind=='outlier': v=a+(7 if i==n//3 else -6 if i==n//2 else 0)
   elif kind=='rescaled': v=a*3000
   elif kind=='nearflat': v=0.25+a*1e-7
   elif kind=='offset': v=2.3+a
   elif kind=='small': v=a*1e-4
   elif kind=='wide': v=a*30+4
   elif kind=='trend': v=i/n+a/6
   elif kind=='alternating': v=(-1 if i%2 else 1)*(1.1+a/20)
   elif kind=='skewed': v=abs(a)**2-0.5
   elif kind=='clustered': v=(0.75 if i%3 else -0.75)+a/40
   elif kind=='exponential': v=1.02**(i-n//2)+a/80
   x.append(v)
  y=[0.72+0.31*v+r.gauss(0,0.16) for v in x]
  rows.append({'id':f'prospective_{kind}_n{n}_seed20261113','x':x,'y':y})
assert len(rows)==72 and len(set(t['id'] for t in rows))==72
p=Path(__file__).with_name('input.json');p.write_text(json.dumps({'schema':'CINGULUM_MATLAB_QR_SOURCE_UNSEEN_PROSPECTIVE_V1','generation_seed':202611130173,'cases':rows},separators=(',',':'))+'\n')
print('PROSPECTIVE_INPUT_SHA256',hashlib.sha256(p.read_bytes()).hexdigest(),len(rows))
