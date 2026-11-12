#!/usr/bin/env python3
"""Exhaustive rooted triple probes for ORIGINAL MATLAB binary64 GEMV topology.

For every unordered {a,b,c} at each length, the three possible ±2^54
cancellation pairs give a rooted triplet signature. Input is indices only;
MATLAB constructs matrices using exactly representable IEEE754 powers of two,
not externally produced double intermediates. With y=1, multiplication is exact.
Never use original source outputs as independent Rust numerical inputs.
"""
from pathlib import Path
from itertools import combinations
from hashlib import sha256
import json,math
lengths=(9,10,11,12,15,16,17,18,23,24,25,32)
cases=[{'id':f'topology_n{n}_a{a}_b{b}_c{c}','n':n,'triple':[a+1,b+1,c+1]}
       for n in lengths for a,b,c in combinations(range(n),3)]
expected=sum(math.comb(n,3) for n in lengths)
assert len(cases)==expected and len(set(q['id'] for q in cases))==expected
assert all(q['triple']==sorted(q['triple']) and q['triple'][0]>=1 and q['triple'][-1]<=q['n'] for q in cases)
record={'schema':'ORIGINAL_MATHWORKS_R2026B_GEMV_EXHAUSTIVE_ROOTED_TRIPLE_CANCELLATION_TOPOLOGY_V1',
        'original_numerical_primitive':'Original MATLAB public Q-transpose times y, two Q columns',
        'original_build_Q_terms':['+2^54','-2^54','+1','+0'],
        'original_y_all_exact_one':True,'source_blind_independent_Rust_topology_NOT_PRECOMMITTED':True,
        'lengths':lengths,'triples':cases,'count':expected}
p=Path(__file__).with_name('input.json');p.write_text(json.dumps(record,separators=(',',':'),sort_keys=True)+'\n')
print('ORIGINAL_GEMV_ROOTED_TRIPLE_TOPOLOGY_SOURCE_INPUT',expected,'triplets across',len(lengths),'lengths','MATLAB matrix products',expected*2,'SHA256',sha256(p.read_bytes()).hexdigest())
