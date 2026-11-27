"""V1422 case list: single and mixed single/double kernels (source-disclosed, black box).
Grammar: case,seed,op,cls,n,m,q
  corr  cls in {sd,ds,ss}: [r,p] = corr(X,y), X n x m class cls[0], y n x 1 class cls[1]
  pc    cls in {sdd,dsd,dds,ssd}: [r,p] = partialcorr(X,y,Z), Z n x q; also [ones Z]\\[X y] as partialcorr would form it
  ml    cls in {ss,sd,ds}: X = A\\B, A = [ones(n,1) Z] (n x (q+1), class cls[0]), B n x m (class cls[1]); [~,R,E] = qr(A,0)
  rg    cls in {ss,sd,ds}: X = [Z ones] (n x (m+1), class cls[0]), y (class cls[1]); [Q,R,perm] = qr(X,0), Q'*y, R\\(Q'*y), regress(y,X)
  sum   cls s: sum(X) for X n x m single
  mt    cls in {ss,ds,sd}: X*b, X n x m, b m x 1
Seeds 142,200,000 + case. Inputs come from gen() (an integer hash, exact in single and double)."""
import csv, sys
rows = []
def add(op, cls, n, m, q=0):
    c = len(rows) + 1
    rows.append((c, 142200000 + c, op, cls, n, m, q))
W = [1, 2, 3, 4, 5, 6, 7, 8, 9, 12, 13, 14, 15, 16, 17, 28, 31, 33, 66, 78, 153, 190, 351]
N = [3, 4, 5, 8, 13, 14, 15, 16, 17, 33, 49, 50, 51, 52, 57, 70, 100, 113, 126, 130, 257, 385]
for cls in ("sd", "ds", "ss"):
    for n in N:
        for m in W:
            add("corr", cls, n, m)
for cls, n in (("sd", 385), ("ds", 385), ("ss", 385), ("sd", 771), ("ds", 771)):
    add("corr", cls, n, 35778)
PW = [1, 2, 3, 5, 8, 17, 28, 66, 153, 351]
PN = [5, 8, 14, 15, 16, 17, 33, 51, 57, 70, 126, 130, 257, 385]
for cls in ("sdd", "dsd", "dds"):
    for n in PN:
        for m in PW:
            add("pc", cls, n, m, 1)
for cls in ("sdd", "dsd", "dds", "ssd"):
    for n in (8, 17, 57, 130):
        for m in (3, 28):
            for q in (2, 3):
                add("pc", cls, n, m, q)
for cls, n in (("sdd", 385), ("dsd", 771), ("dds", 385), ("dsd", 385)):
    add("pc", cls, n, 35778, 1)
for cls in ("ss", "sd", "ds"):
    for q in (1, 2, 3):
        for n in (3, 4, 5, 8, 14, 15, 16, 17, 33, 51, 57, 130, 385):
            if n < q + 1:
                continue
            for m in (1, 2, 3, 4, 5, 8, 17, 66):
                add("ml", cls, n, m, q)
for cls in ("ss", "sd", "ds"):
    for m in (1, 2):
        for n in (3, 4, 5, 8, 9, 14, 15, 16, 17, 31, 32, 33, 50, 51, 57, 70, 100, 113, 126, 130, 257, 385, 771):
            add("rg", cls, n, m)
for n in list(range(1, 121)) + [128, 200, 256, 385, 400, 500, 771, 1000]:
    add("sum", "s", n, 3)
for cls in ("ss", "ds", "sd"):
    for n in list(range(1, 21)) + [50, 100, 200]:
        for m in (2, 3):
            add("mt", cls, n, m)
w = csv.writer(sys.stdout, lineterminator="\n")
w.writerow(["case", "seed", "op", "cls", "n", "m", "q"])
w.writerows(rows)
