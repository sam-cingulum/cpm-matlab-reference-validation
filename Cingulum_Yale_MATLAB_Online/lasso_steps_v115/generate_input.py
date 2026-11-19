"""Expose the earliest different accepted update on two disclosed stopping paths."""
from pathlib import Path
import hashlib,json
root=Path(__file__).parent
raw=(root.parent/'lasso_support_v111/input.json').read_bytes()
assert hashlib.sha256(raw).hexdigest()=='184aa63133bf5eeeb49a5a466b96d79f5cd11af2d14dfa9acede01f387a2630e'
q=json.loads(raw)
rows=[]
for name,std,grid,last in [('support_504',True,[.125,.03125],175),('support_574',False,[1.25,.0625],260)]:
    case=next(v for v in q if v['id']==name)
    rows.append(dict(case,standard=std,grid=grid,last=last))
path=root/'input.json';path.write_text(json.dumps(rows,separators=(',',':'))+'\n')
path.with_suffix('.sha256').write_text(hashlib.sha256(path.read_bytes()).hexdigest()+'  input.json\n')
