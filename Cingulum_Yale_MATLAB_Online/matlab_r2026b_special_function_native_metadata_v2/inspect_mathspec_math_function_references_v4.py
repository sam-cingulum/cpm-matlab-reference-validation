#!/usr/bin/env python3
"""Read metadata-only symbol and branch destination families from installed MATLAB.

Does NOT export MathWorks object bytes, assembly, algorithm code, constants or
numeric outputs. This is only for distinguishing a wrapper from the actual
mathematical algorithm and finding available public math-library candidates.
"""
from __future__ import annotations
import collections,hashlib,json,pathlib,re,subprocess,sys
def run(args,timeout=60):
    p=subprocess.run(args,text=True,stdout=subprocess.PIPE,stderr=subprocess.PIPE,timeout=timeout)
    if p.returncode:raise RuntimeError((args[:2],p.stderr[:1000]))
    return p.stdout
def digest(p):
    h=hashlib.sha256()
    with p.open("rb") as f:
        for blk in iter(lambda:f.read(1024*1024),b""):h.update(blk)
    return h.hexdigest()
def main():
    assert len(sys.argv)==3
    lib=pathlib.Path(sys.argv[1])/"bin/glnxa64/libmwmathspec.so"
    assert lib.is_file()
    syms=run(["nm","-D","-S","--defined-only","-C",str(lib)],90)
    pattern=re.compile(r"^([0-9a-fA-F]+)\s+([0-9a-fA-F]+)\s+([A-Za-z])\s+(.+)$")
    rows=[]
    for l in syms.splitlines():
        m=pattern.match(l)
        if m:
            rows.append({"addr":int(m.group(1),16),"size":int(m.group(2),16),"symbol":m.group(4)})
    addresses={r["addr"]:r["symbol"] for r in rows}
    funcs=[r for r in rows if r["symbol"].startswith("mathspec::") and "betainc(" in r["symbol"]]
    assert len(funcs)==1
    target=funcs[0]
    start=target["addr"];end=start+target["size"]
    lines=run(["objdump","--no-show-raw-insn","-d","-M","intel",
               "--start-address",hex(start),"--stop-address",hex(end),str(lib)],60).splitlines()
    branches=[]
    for l in lines:
        m=re.match(r"\s*([0-9a-fA-F]+):\s+([A-Za-z][\w.]*)\s+([0-9a-fA-F]+)(?:\s|$)",l)
        if not m:continue
        addr=int(m.group(1),16);op=m.group(2)
        if not (op.startswith("call") or op.startswith("jmp") or (op.startswith("j") and op not in ("jmp","jmpq"))):continue
        dst=int(m.group(3),16)
        if op.startswith("call"):kind="call"
        elif op.startswith("jmp"):kind="jump"
        else:kind="conditional_jump"
        branch={"kind":kind,"source_offset_from_export_bytes":addr-start,
                "target_is_within_export":start<=dst<end,
                "target_is_exported_symbol":dst in addresses,
                "target_exported_name":addresses.get(dst),
                "target_location":"within_export" if start<=dst<end else "other_code_region"}
        # All jump targets are potentially compilation-local. Exporting target
        # addresses is NOT mathematical algorithm code or an exact function
        # boundary; offsets are used only to compare future artifacts.
        branch["target_library_relative_offset_hex"]=hex(dst)
        branches.append(branch)
    boost_hits=[]
    for r in rows:
        name=r["symbol"]
        if "mwboost::math::" in name or "boost::math::" in name:
            if any(token in name.lower() for token in ("beta","gamma","lanczos","ibeta","lgamma","erf","detail")):
                boost_hits.append({"name":name,"size_bytes":r["size"]})
    result={
      "classification":"R2026B_VENDOR_EXPORTED_MATH_KERNEL_FORWARDING_TOPOLOGY_METADATA_ONLY",
      "vendor_binary_or_assembly_published":False,
      "numerical_output_provided_to_Rust":False,
      "vendor_library_sha256":digest(lib),
      "wrapper_name":target["symbol"],
      "wrapper_size_bytes":target["size"],
      "branches":branches,
      "boost_math_relevant_exported_symbol_count":len(boost_hits),
      "boost_math_relevant_exported_symbols":boost_hits[:120],
      "next_phase":"Identify exact hidden computation paths from metadata and test general mathematical structure independently in pure Rust. No original numeric answer injection."
    }
    out=pathlib.Path(sys.argv[2])
    out.parent.mkdir(parents=True,exist_ok=True)
    out.write_text(json.dumps(result,indent=2,sort_keys=True)+"\n")
    print("MATHSPEC_SYMBOL",target["symbol"],"SIZE",target["size"])
    for b in branches:print("BRANCH",json.dumps(b,sort_keys=True))
    print("BOOST_MATH_RELEVANT_EXPORTS",len(boost_hits))
    for b in boost_hits[:40]:print("BOOST_FUNCTION",b["name"])
    print("SHA",digest(out))
if __name__=="__main__":main()
