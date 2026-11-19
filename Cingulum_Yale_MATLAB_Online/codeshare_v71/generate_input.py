"""Generate synthetic v5 MAT files for the original script's three named inputs."""
import hashlib
import math
from pathlib import Path
import random
import struct

def element(kind, data):
    return struct.pack("<II",kind,len(data))+data+b"\0"*(-len(data)%8)

def matrix(name, shape, data):
    assert len(data)==math.prod(shape)
    return element(14, element(6,struct.pack("<II",6,0))+element(5,struct.pack("<"+"i"*len(shape),*shape))+
                   element(1,name.encode())+element(9,struct.pack("<"+"d"*len(data),*data)))

folder=Path(__file__).parent
manifest=[]
for trial,(n,d) in enumerate(((19,4),(23,5),(31,6),(42,4),(51,5),(65,6))):
    rng=random.Random(710313+trial)
    age=[rng.randint(18,75) for _ in range(n)]
    y=[rng.randrange(-30,31)/8 for _ in range(n)]
    mats=[]
    for value in y:
        m=[[0.]*d for _ in range(d)]
        for j in range(d):
            for i in range(j+1):
                coef=(0,-.75,1.25,0,.25)[(i+2*j)%5]
                m[i][j]=m[j][i]=round((value*coef+rng.randint(-65,65)/32)*4)/4
        mats.extend(m[i][j] for j in range(d) for i in range(d))
    p=folder/f"codeshare_{n}.mat"
    head=b"MATLAB 5.0 MAT-file, deterministic synthetic CPM fixtures".ljust(116,b" ")+b"\0"*8+b"\0\1IM"
    p.write_bytes(head+matrix("test_mat",[d,d,n],mats)+matrix("test_score",[n,1],y)+matrix("test_cov",[n,1],age))
    manifest.append(hashlib.sha256(p.read_bytes()).hexdigest()+"  "+p.name)
(folder/"input.sha256").write_text("\n".join(manifest)+"\n")
