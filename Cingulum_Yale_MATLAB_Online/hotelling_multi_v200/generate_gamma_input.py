"""New V200 original-blind gamma test-input generator, no oracle outcomes.

144 prospective scaled-upper incomplete-gamma inputs, shapes beyond the
previous 0.5–3.0 ladder, independently randomized large-x argument centers,
and adjacent raw IEEE binary64 numbers. Outputs deterministic SHA-pinned
original-source data only. No MATLAB or Rust expected answers in this file.
"""
import hashlib
import json
import math
import random
import struct
from pathlib import Path

rng = random.Random(2001122149)
rows = []
for shape in (0.5, 1.5, 2.5, 3.5, 4.5, 5.5):
    for window in range(8):
        # 8 randomized decades/regions, not reusing previous source values.
        low, high = (
            (40, 65), (65, 130), (130, 250), (250, 600),
            (600, 1400), (1400, 4000), (4000, 11000), (11000, 30000)
        )[window]
        center = math.exp(rng.uniform(math.log(low), math.log(high)))
        center_bits = struct.unpack(">Q", struct.pack(">d", center))[0]
        for adj in (-1, 0, 1):
            x = struct.pack(">Q",center_bits+adj).hex()
            a = struct.pack(">d",shape).hex()
            rows.append({"id":f"gamma_v200_{len(rows)}","x":x,"shape":a})

assert len(rows)==144 and len({r["id"] for r in rows})==144
dest=Path(__file__).with_name("gamma_input.json")
dest.write_text(json.dumps(rows,separators=(",",":"))+"\n")
(dest.parent/"gamma_input.sha256").write_text(
    hashlib.sha256(dest.read_bytes()).hexdigest()+"  gamma_input.json\n")
print("NEW original-only gamma scalar SHA",hashlib.sha256(dest.read_bytes()).hexdigest())
