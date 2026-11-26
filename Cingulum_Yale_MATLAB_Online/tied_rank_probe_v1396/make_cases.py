"""V1396 probe cases (source-disclosed diagnostic, not a firstblind).

case,seed,kind,n,m,mod
kind: eq = corr Spearman of a tied y with itself, with -y and beside an untied column;
ex = corr Spearman of every x in {1..k}^n against fixed tied y patterns (one matrix call and
one call per column); kd = corr Kendall with ties for 6 to 9 subjects (and 5, 10 as anchors).
"""
import sys
rows = []
def add(kind, n, m=0, mod="-"):
    c = len(rows) + 1
    rows.append(f"{c},{139600000 + c},{kind},{n},{m},{mod}")
for n in list(range(3, 21)) + [25, 30, 44, 50, 100, 300, 1000]:
    add("eq", n, 40)
for y in ["1;1;2;3", "1;2;2;3", "1;1;2;2", "1;1;1;2", "1;2;3;4", "2;1;1;3"]:
    add("ex", 4, 4, y)
for y in ["1;1;2;3;4", "1;2;2;2;3", "1;1;2;2;3", "1;1;1;2;2", "1;2;3;4;5", "3;1;2;2;1"]:
    add("ex", 5, 3, y)
for n in [5, 6, 7, 8, 9, 10]:
    for k in [2, 3, 5]:
        add("kd", n, 100, str(k))
out = "case,seed,kind,n,m,mod\n" + "\n".join(rows) + "\n"
open(sys.argv[1], "w").write(out)
print(len(rows))
