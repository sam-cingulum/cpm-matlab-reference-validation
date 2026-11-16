#!/usr/bin/env python3
"""Structural metadata for SHA-pinned MathWorks R2026b gammaln hidden numeric region.

No vendor instruction/operand/constant bytes, vendor sources, or mathematical
outputs are redistributed. Region does NOT establish mathematical function
boundaries or bit-exact Rust compatibility; it is diagnostic architecture.
"""
from __future__ import annotations
import collections,hashlib,json,pathlib,re,subprocess,sys
SHA="625bc659a790963d52dca039c66bcbde68c319caba37f89b85dd977c6a3be848"
def command(a):
    p=subprocess.run(a,capture_output=True,text=True,timeout=90,check=False)
    if p.returncode:raise RuntimeError(p.stderr[:1000])
    return p.stdout
def digest(p):
    h=hashlib.sha256()
    with p.open("rb") as f:
        for x in iter(lambda:f.read(1024*1024),b""):h.update(x)
    return h.hexdigest()
def code_segment(lib,start,end):
    data=command(["objdump","-d","--no-show-raw-insn","-M","intel",
             "--start-address",hex(start),"--stop-address",hex(end),str(lib)])
    rows=[]
    for line in data.splitlines():
        m=re.match(r"\s*([0-9a-fA-F]+):\s+([A-Za-z][\w.]*)\s*(.*?)\s*$",line)
        if m:
            addr=int(m.group(1),16)
            if start<=addr<end:rows.append((addr,m.group(2),m.group(3)))
    return rows
def summary(rows,start,end):
    h=collections.Counter(op for _,op,_ in rows)
    families={
        "add_sub_scalar_double":sum(v for k,v in h.items() if re.fullmatch(r"v?(?:add|sub)sd",k)),
        "mul_scalar_double":sum(v for k,v in h.items() if re.fullmatch(r"v?mulsd",k)),
        "div_scalar_double":sum(v for k,v in h.items() if re.fullmatch(r"v?divsd",k)),
        "sqrt_scalar_double":sum(v for k,v in h.items() if re.fullmatch(r"v?sqrtsd",k)),
        "FMA":sum(v for k,v in h.items() if re.search(r"fmadd|fmsub|fnmadd|fnmsub",k)),
        "conditional_branch":sum(v for k,v in h.items() if k.startswith("j") and not k.startswith("jmp")),
        "unconditional_jump":sum(v for k,v in h.items() if k.startswith("jmp")),
        "direct_call":sum(v for k,v in h.items() if k.startswith("call")),
        "ret":sum(v for k,v in h.items() if k.startswith("ret")),
    }
    dst=collections.Counter()
    for addr,mn,operand in rows:
        if not (mn.startswith("call") or mn.startswith("jmp")):continue
        m=re.match(r"([0-9a-fA-F]+)(?:\s|$)",operand)
        if m:
            p=int(m.group(1),16)
            dst[("call" if mn.startswith("call") else "jump",hex(p))]+=1
    return {
       "analysis_begin":hex(start),"analysis_end":hex(end),
       "analysis_length_bytes":end-start,
       "instruction_count":len(rows),
       "counts":families,
       "first_return_offsets_from_start":[hex(addr-start) for addr,mn,_ in rows if mn.startswith("ret")][:30],
       "targets":[{"kind":kind,"relative_target":address,"count":n}
           for (kind,address),n in sorted(dst.items(),key=lambda kv:(-kv[1],kv[0]))[:70]]
    }
def main():
    assert len(sys.argv)==3
    root=pathlib.Path(sys.argv[1])
    lib=root/"bin/glnxa64/libmwmathspec.so"
    assert lib.is_file() and digest(lib)==SHA
    name="mathspec::gammaln(double)"
    nms=command(["nm","-D","-S","--defined-only","-C",str(lib)])
    symbols=[]
    for s in nms.splitlines():
        m=re.match(r"([0-9a-fA-F]+)\s+([0-9a-fA-F]+)\s+[A-Za-z]\s+(.*)$",s)
        if m and m.group(3) in (name,"mathspec::gamma(double)"):
           symbols.append({"name":m.group(3),"addr":int(m.group(1),16),
                           "size":int(m.group(2),16)})
    assert len(symbols)==2
    entry=0x8f1e0  # Original SHA-verified V5 gamma forwarding target
    region=summary(code_segment(lib,entry,entry+4096),entry,entry+4096)
    assert region["instruction_count"]>=20
    wrappers=[]
    for s in symbols:
        r=code_segment(lib,s["addr"],s["addr"]+s["size"])
        assert s["size"]==5 and len(r)>=1
        wrappers.append({"exported_symbol":s["name"],"forwarder":summary(r,s["addr"],s["addr"]+s["size"])})
    report={
       "classification":"R2026B_SHA_LOCKED_GAMMA_HIDDEN_CODE_REGION_STRUCTURAL_METADATA_ONLY_V6",
       "vendor_library_sha256":SHA,
       "vendor_code_copied":False,
       "function_bounds_proven":False,
       "authentic_original_numeric_outputs_provided_to_compiled_Rust":False,
       "observed_gamma_wrapper_target":hex(entry),
       "hidden_gamma_region_metadata":region,
       "short_gamma_export_symbols":wrappers,
       "source_unseen_V12":"NOT_GENERATED",
       "statistical_original_binary64_parity":"STILL_UNPROVEN"
    }
    out=pathlib.Path(sys.argv[2]);out.parent.mkdir(parents=True,exist_ok=True)
    out.write_text(json.dumps(report,sort_keys=True,indent=2)+"\n")
    print("GAMMA_HIDDEN_4K_REGION",json.dumps(region["counts"],sort_keys=True))
    for v in wrappers: print("WRAPPER",v["exported_symbol"],v["forwarder"]["targets"])
    print("FIRST_RET_OFFSETS",region["first_return_offsets_from_start"][:25])
    print("POTENTIAL_CALL_TARGETS",region["targets"][:30])
    print("REPORT_SHA",digest(out))
    print("NOT_MATHWORKS_NUMERICAL_CODE_OR_COMPLETE_RUST_PARITY")
if __name__=="__main__":main()
