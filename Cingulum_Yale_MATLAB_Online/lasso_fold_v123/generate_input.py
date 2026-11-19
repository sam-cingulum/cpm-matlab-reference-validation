"""Select the disclosed V119 cohort with the fold-8 loss difference, and neighboring controls."""
from pathlib import Path
import hashlib,json
p=Path(__file__).with_name("input.json")
raw=(p.parent.parent/"lasso_cv_dense_v119/input.json").read_bytes()
assert hashlib.sha256(raw).hexdigest()=="b4895b4d5575cdd39653deadb9c85ae464fbec650a116f3126688f849b895ff5"
q=json.loads(raw)[-1]
p.write_text(json.dumps(q,separators=(",",":"))+"\n")
p.with_suffix(".sha256").write_text(hashlib.sha256(p.read_bytes()).hexdigest()+"  input.json\n")
