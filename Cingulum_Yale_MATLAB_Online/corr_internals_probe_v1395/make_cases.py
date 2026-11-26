"""V1395 probe cases (source-disclosed diagnostic, not a firstblind).

case,seed,kind,n,m,q,mod
kind: kt = corr(X, y, 'type', 'Kendall') without ties; kv = the chain f = conv(f, ones(1,k)),
k = 2..n, with cumsum and factorial; st = corr Spearman with ties beside MATLAB's own
tiedrank outputs and Pearson corr of those ranks; pz = partialcorr with columns (or y) a
swept distance from the span of [ones Z], with MATLAB's own [ones Z] \\ x residuals; in = corr,
partialcorr and regress with integer, logical and single classes.
"""
import sys

rows = []


def add(kind, n, m=0, q=0, mod="-"):
    c = len(rows) + 1
    rows.append(f"{c},{139500000 + c},{kind},{n},{m},{q},{mod}")


for n in range(2, 52):
    add("kt", n, 100)
for n in range(8, 50):
    add("kv", n)
for n in [3, 4, 5, 6, 7, 8, 9, 10, 12, 15, 20, 30, 50, 100, 300, 1000]:
    for t in ["y", "x", "xy", "heavy", "one"]:
        add("st", n, 40 if n <= 100 else 12, mod=t)
for n in [8, 20, 60, 300, 1000]:
    for q in [1, 3]:
        add("pz", n, 105, q, mod="x")
        add("pz", n, 20, q, mod="y")
        add("pz", n, 40, q, mod="xs")
for mod in ["yint16", "yint32", "yuint8", "ylogical", "xint16", "xlogical", "ysingle",
            "xsingle", "pyint16", "pxint16", "pzint16", "rgyint16", "rgxint16", "rgysingle"]:
    for n in [12, 40]:
        add("in", n, 20, 1, mod=mod)

out = "case,seed,kind,n,m,q,mod\n" + "\n".join(rows) + "\n"
open(sys.argv[1], "w").write(out)
print(len(rows))
