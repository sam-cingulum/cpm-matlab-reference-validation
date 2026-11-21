"""Original-only, source-disclosed numeric gamma branch probe.

This input is intended for inspecting MathWorks rounding at large arguments,
not a preregistered predictive certification. No Yale forecasts are used.
"""
from pathlib import Path
import hashlib
import struct

HERE=Path(__file__).resolve().parent
centers=[
    "40916f4b2766c666",  # previously disclosed x~1115.82
    "40c86f35043dc640",  # previously disclosed x~12510.4
]
extras=[
    "4048592f2fbc126c",  # binary64 x=48.696752516586315
    "4059000000000000",  # 100
    "40885cbd6c05b8a8",  # x~779.59
    "40a8fe87578ee31e",  # x~3199.26
    "4011f73a10fa53b8",  # original V197 4.491...
]
values=[]
for center in centers:
    c=int(center,16)
    values.extend(range(c-1,c+2))
values.extend(int(z,16) for z in extras)
values=sorted(set(values))
shapes=[0.5,1.5,2.5]
rows=[f"{v:016x} {struct.pack('>d',a).hex()}" for v in values for a in shapes]
raw=("\n".join(rows)+"\n").encode()
(HERE/"probes.txt").write_bytes(raw)
(HERE/"input.sha256").write_text(f"{hashlib.sha256(raw).hexdigest()}  probes.txt\n")
print("source-disclosed rows",len(rows),"input SHA",hashlib.sha256(raw).hexdigest())
