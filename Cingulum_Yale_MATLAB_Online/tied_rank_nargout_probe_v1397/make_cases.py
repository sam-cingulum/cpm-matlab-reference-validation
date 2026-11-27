"""V1397 probe cases (source-disclosed diagnostic, not a firstblind).

case,seed,kind,n,m,mod
kind: nx = every x in {1..k}^n against a fixed tied y (mod), k = m;
nr = m random tied columns (values round(randn*mod)) against a tied y of n rows.
Each case measures corr Spearman with one output and with two, with the arguments swapped,
with 'tail','right', and corr Pearson of tiedrank(x) and tiedrank(y) with one and two outputs.
"""
import sys
rows = []
def add(kind, n, m, mod):
    c = len(rows) + 1
    rows.append(f"{c},{139700000 + c},{kind},{n},{m},{mod}")
for y in ["1;1;2;3", "1;1;2;2", "1;1;1;2", "1;2;3;4"]:
    add("nx", 4, 4, y)
for y in ["1;1;2;3;4", "1;2;2;2;3", "1;2;3;4;5"]:
    add("nx", 5, 3, y)
for n in list(range(3, 13)) + [15, 20, 30, 50, 100, 300, 1000]:
    for k in ["1.5", "4"]:
        add("nr", n, 40, k)
out = "case,seed,kind,n,m,mod\n" + "\n".join(rows) + "\n"
open(sys.argv[1], "w").write(out)
print(len(rows))
