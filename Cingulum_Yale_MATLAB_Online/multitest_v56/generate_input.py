"""Seeded binary64 input, tie and decision-boundary fixtures for four distinct methods."""
import hashlib,json,math,random,struct
from pathlib import Path
rng=random.Random(2026111956)
rows=[]
bits=lambda x:struct.pack('>d',x).hex()
for i,n in enumerate([1,3,5,6,12,22,37,42,44,46,55,64,72,96,130,192,255,513,1024]):
    for mode in ('continuous','tied','threshold','null'):
        alpha=(.125,.05,.375)[i%3]
        p=[rng.random()**3 for _ in range(n)]
        if mode=='tied': p=[rng.choice([0.,.003,.025,.125,.5,1.]) for _ in p]
        if mode=='threshold':
            p=[min(1.,max(0., math.nextafter((j+1)*alpha/n, 0. if j%3==0 else 1.) if j%3!=2 else (j+1)*alpha/n)) for j in range(n)]
            rng.shuffle(p)
        if mode=='null':p=[.7+.3*z for z in p]
        shape=([n,1] if i%2==0 else [1,n])
        if n==64:shape=[4,4,4]
        if n==6:shape=[2,3]
        rows.append(dict(id=f'v56_{n}_{mode}',shape=shape,p_hex=[bits(z) for z in p],alpha_hex=bits(alpha)))
p=Path(__file__).with_name('input.json');p.write_text(json.dumps(rows,separators=(',',':'))+'\n')
p.with_name('input.sha256').write_text(hashlib.sha256(p.read_bytes()).hexdigest()+'  input.json\n')
