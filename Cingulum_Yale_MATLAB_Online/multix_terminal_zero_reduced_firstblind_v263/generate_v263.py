#!/usr/bin/env python3
"""V263 independent prospective raw double-matrix terminal-zero QR challenge.

No MATLAB output is consulted to generate the preregistered synthetic X/y.
The generator is committed to the public original-only source repository.
Native Rust reduced-row forecasts and scorer MUST be frozen and remotely
committed before any genuine MATLAB R2026b original is executed.
"""
import hashlib
import json
import math
import random
import struct
from pathlib import Path

SEED=202611220263
ROW_COUNTS=(35,36,43,44,47,48,61,62,71,72,87,88)
WIDTHS=(3,4,5,6)
FAMILIES=("dense","correlated","scaled","shifted")
HERE=Path(__file__).resolve().parent
def hx(v:float)->str:
 assert math.isfinite(v)
 return struct.pack('>d',float(v)).hex()
def generate():
 rows=[]
 for index,n in enumerate(ROW_COUNTS):
  for p in WIDTHS:
   rng=random.Random(SEED+1009*n+17*p)
   family=FAMILIES[(index+p)%len(FAMILIES)]
   latent=[rng.gauss(0.,1.) for _ in range(n-1)]
   cols=[[1.]*n]
   for j in range(1,p):
    col=[]
    for i in range(n-1):
     z=rng.gauss(0.,1.)
     if family=='dense':
      val=z+(i%7-3)*0.004
     elif family=='correlated':
      val=0.84*latent[i]+0.16*z+0.033*j
     elif family=='scaled':
      val=z*(0.3+0.38*j)+0.025*latent[i]
     else:
      val=0.4*j+z*0.51+0.22*latent[i]
     col.append(float(val))
    col.append(0.)
    cols.append(col)
   cols[0][-1]=0.
   beta=[rng.uniform(-1.,1.) for _ in range(p)]
   y=[]
   for i in range(n-1):
    v=sum(cols[j][i]*beta[j] for j in range(p))
    v+=rng.gauss(0.,0.14)
    if i%17==0:v+=(-1. if i%2 else 1.)*0.75
    y.append(float(v))
   y.append(0.)
   assert len(cols)==p and all(len(v)==n and v[-1]==0. for v in cols)
   assert y[-1]==0.
   case={
     "id":f"v263_{family}_n{n}_p{p}_seed{SEED}",
     "family":family,"n":n,"p":p,
     "a_colmajor_hex":[hx(v) for c in cols for v in c],
     "b_hex":[hx(v) for v in y],
   }
   assert len(case['a_colmajor_hex'])==n*p and len(case['b_hex'])==n
   rows.append(case)
 assert len(rows)==48
 payload={
  "classification":"CINGULUM_V263_PROSPECTIVE_TERMINAL_ZERO_REDUCED_ROW_MLDIVIDE",
  "seed":SEED,"cohorts":48,
  "row_counts":list(ROW_COUNTS),"matrix_widths":list(WIDTHS),
  "source_original_MATLAB_numeric_results_consulted":False,
  "first_original_blind_V252_verdict_unchanged":"FAIL",
  "original_MATLAB_reduced_row_output_not_yet_seen":True,
  "cases":rows,
 }
 raw=(json.dumps(payload,sort_keys=True,separators=(',',':'))+'\n').encode()
 path=HERE/'input.json'
 path.write_bytes(raw)
 (HERE/'input.sha256').write_text(f"{hashlib.sha256(raw).hexdigest()}  input.json\n")
 print('V263_FRESH_SOURCE_UNSEEN_INPUT_SHA',hashlib.sha256(raw).hexdigest())
 print('V263_CASES',len(rows),'FROZEN_NEW_ROW_COUNTS',ROW_COUNTS,'WIDTHS',WIDTHS)
if __name__=='__main__':generate()
