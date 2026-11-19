"""Dense 4D Yale fits with more than 64 selected predictors in outer and inner folds."""
from pathlib import Path
import hashlib,json,random,struct
rng=random.Random(1289711);bits=lambda v:struct.pack(">d",v).hex()
rows=[]
for j,(nr,nc,t,n,penalty) in enumerate([(12,11,1,67,.5),(23,13,1,53,[.275,.75,1.125]),(20,15,1,59,[.18,.444444,1.234567]),
   (43,7,1,63,[.0625,.375,2.34567]),(11,11,2,65,[]),(14,11,2,73,[]),
   (16,10,3,57,[.02,.03125,.08]),(12,9,4,77,[])]):
    y=[rng.gauss(.2,1.) for _ in range(n)]
    if j%3==1:y=[round(x*3)/3 for x in y]
    mat=[];sym=nr==nc
    for task in range(t):
        for value in y:
            slab=[0.]*(nr*nc)
            for col in range(nc):
                for row in range(col+1 if sym else 0,nr):
                    signal=(.8+((row+col)%5)/5)*value*(-1)**(row+col+task)
                    v=rng.gauss(.04*col,.85)+signal
                    slab[row+col*nr]=v
                    if sym:slab[col+row*nr]=v
            mat.extend(slab)
    k=3+(j%2);labels=[i%k+1 for i in range(n)] if j%2 else [];rng.shuffle(labels)
    rows.append(dict(id=f"ridge_limit_{j}",shape=[nr,nc,n,t],matrix=list(map(bits,mat)),outcomes=list(map(bits,y)),
                     threshold=.2,alpha=(1e-6,.375,.65)[j%3],lambda_value=penalty,k=k,
                     seed=rng.randrange(1000000),fold_labels=labels))
p=Path(__file__).with_name("input.json");p.write_text(json.dumps(rows,separators=(",",":"))+"\n")
p.with_suffix(".sha256").write_text(hashlib.sha256(p.read_bytes()).hexdigest()+"  input.json\n")
