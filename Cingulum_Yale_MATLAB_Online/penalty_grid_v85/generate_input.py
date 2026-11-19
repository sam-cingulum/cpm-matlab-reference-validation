"""Known disclosed boundary and independent positive scalars for the public grid operations."""
import hashlib,json,math,random,struct
from pathlib import Path
rng=random.Random(850039)
cases=[]
for i in range(240):
    n=(16,16,16,2,7,17,31,64)[i%8]
    if i<17:
        v=struct.unpack('>d',(int('4058d1794dd7ca88',16)+i-8).to_bytes(8,'big'))[0]
        n=16
    else:
        v=math.ldexp(rng.uniform(.5,1.),rng.randrange(-12,23))
    cases.append(dict(id=f'grid_{i}',high=struct.pack('>d',v).hex(),n=n))
p=Path(__file__).with_name('input.json')
p.write_text(json.dumps(cases,separators=(',',':'))+'\n')
p.with_suffix('.sha256').write_text(hashlib.sha256(p.read_bytes()).hexdigest()+'  input.json\n')
