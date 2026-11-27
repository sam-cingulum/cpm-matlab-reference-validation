"""V1423 case list: single and mixed single/double kernels on Mersenne-twister data (source-disclosed, black box).
Grammar: case,seed,op,cls,n,m,q
Inputs: rng(seed,'twister'), then in this order X0 = rand(n,m), y0 = rand(n,1), Z0 = rand(n,q),
E0 = rand(n,m) (corrhi only); every value minus 0.5 (exact in binary64), then single() where the
class letter is s. V1422 used an integer hash whose columns were near-shifted copies; these are not.
  corr    cls in {sd,ds,ss}: [r,p] = corr(X,y), X class cls[0], y class cls[1]
  corrhi  cls in {sd,ds,ss}: as corr, but column j of X is (-1)^j*y0 + 2^-(q+j-1)*E0(:,j) (in binary64,
          before the class cast), so r runs toward +-1 and p toward 0 and the subnormal range
  pc      cls = classes of X, y, Z: [ones Z]\\[X y], its residual (width < 1000), [r,p] = partialcorr(X,y,Z)
  ml      cls in {ss,sd,ds}: A = [ones(n,1) Z] (class cls[0]), B = X (class cls[1]); A\\B and [~,R,E] = qr(A,0)
  rg      cls in {ss,sd,ds}: X = [Z ones] with Z = X0, y; [Q,R,perm] = qr(X,0), Q'*y, R\\(Q'*y), regress(y,X)
  sum     cls s: sum(X)
Seeds 142,300,000 + case. Inputs with n*(m+q+1) <= 400 values are also written out (fields in_*)."""
import csv, sys
rows = []
def add(op, cls, n, m, q=0):
    c = len(rows) + 1
    rows.append((c, 142300000 + c, op, cls, n, m, q))
# Width-1 corr, n 49..1000 (the 8-lane region of the double model)
N1 = list(range(44, 81)) + [96, 100, 113, 127, 128, 129, 130, 200, 255, 256, 257, 268, 385, 481, 500, 771, 964, 1000]
for cls in ("sd", "ds", "ss"):
    for n in N1:
        for rep in range(3):
            add("corr", cls, n, 1)
# General widths
W = [2, 3, 4, 5, 8, 13, 15, 16, 17, 33, 66, 153, 351]
N = [4, 5, 8, 14, 15, 16, 17, 33, 50, 51, 57, 68, 100, 130, 141, 162, 257, 385]
for cls in ("sd", "ds", "ss"):
    for n in N:
        for m in W:
            add("corr", cls, n, m)
# df = 1 (n = 3) and df = 2 (n = 4): many p values per case
for cls in ("sd", "ds", "ss"):
    for n in (3, 4):
        for m in (1, 2, 17, 351, 2000):
            for rep in range(4):
                add("corr", cls, n, m)
# r toward +-1, tiny p
for cls in ("sd", "ds", "ss"):
    for n in (3, 4, 5, 8, 17, 50, 68, 141, 385, 964):
        for q in (1, 6, 11, 16, 21, 26):
            add("corrhi", cls, n, 24, q)
# OHBM-scale corr widths (35,778 = 268*267/2)
for cls, n in (("sd", 385), ("sd", 481), ("ds", 481), ("ss", 385), ("sd", 964), ("ds", 771)):
    add("corr", cls, n, 35778)
# partialcorr, every class mix except all-double
PC = ("sdd", "dsd", "dds", "ssd", "sds", "dss", "sss")
for cls in PC:
    for q in (1, 2, 3):
        for n in (5, 8, 14, 17, 33, 57, 68, 130, 162, 385, 964):
            for m in (1, 3, 28, 153):
                add("pc", cls, n, m, q)
for cls, n in (("sdd", 385), ("sdd", 481), ("dsd", 771), ("dsd", 964), ("dds", 385), ("sds", 481), ("dds", 964)):
    add("pc", cls, n, 35778, 1)
# Tall mldivide [ones Z]\B
for cls in ("ss", "sd", "ds"):
    for q in (1, 2, 3):
        for n in (3, 4, 5, 6, 8, 13, 14, 15, 16, 17, 24, 33, 51, 57, 130, 385, 964):
            if n < q + 1:
                continue
            for m in (1, 2, 3, 4, 5, 8, 17, 66, 353):
                add("ml", cls, n, m, q)
# qr / regress re-check on non-degenerate data
for cls in ("ss", "sd", "ds"):
    for m in (1, 2, 3):
        for n in (4, 5, 8, 14, 17, 33, 57, 130, 385, 964):
            add("rg", cls, n, m)
for n in (1, 2, 3, 43, 44, 45, 100, 481, 964, 1000):
    add("sum", "s", n, 3)
w = csv.writer(sys.stdout, lineterminator="\n")
w.writerow(["case", "seed", "op", "cls", "n", "m", "q"])
w.writerows(rows)
