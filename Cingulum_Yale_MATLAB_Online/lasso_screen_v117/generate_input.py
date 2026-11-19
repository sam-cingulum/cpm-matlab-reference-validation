from pathlib import Path
import json,struct,random
def design(i):
    rng=random.Random(1173000+i)
    n=(12,17,23,32,41,56,74,96)[i%8]
    m=(31,37,47)[i%3];alpha=(.37,.7,.95)[i//3%3]
    latent=[rng.gauss(.1,1.) for _ in range(n)]
    columns=[[rng.gauss(.04*j,.8+j/11)+v for v in latent] for j in range(m)]
    y=[rng.gauss(.15,.5)+sum(col[k]*(-1)**j/(1.+j) for j,col in enumerate(columns)) for k in range(n)]
    bits=lambda x:struct.pack(">d",x).hex()
    return dict(id=f"fresh_{i}",n=n,m=m,alpha=alpha,x=[bits(v) for c in columns for v in c],y=list(map(bits,y)))

if __name__=="__main__":
    import hashlib
    # Selected from independent forecasts before any original evaluation.
    chosen=[24,40,41,48,50,55,56,64,65,73,74]
    rows=[design(i) for i in chosen+[1221,1222,1223,1224]]
    # At fixed normalized objective, doubling every observation doubles the raw gradient.
    for i in [24,41,50,55]:
        q=design(i);n=q["n"];columns=[q["x"][j*n:(j+1)*n] for j in range(q["m"])]
        rows.append(dict(q,id=q["id"]+"_twice",n=n*2,x=[v for col in columns for v in col*2],y=q["y"]*2))
    path=Path(__file__).with_name("input.json")
    path.write_text(json.dumps(rows,separators=(",",":"))+"\n")
    path.with_suffix(".sha256").write_text(hashlib.sha256(path.read_bytes()).hexdigest()+"  input.json\n")
