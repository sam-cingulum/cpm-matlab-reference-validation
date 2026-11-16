#!/usr/bin/env python3
"""Characterize installed MATLAB R2026b numerical symbol topology.

No vendor binary or instruction bytes are retained or published.
Outputs only mathematical CPU-operation counts, symbol names, sizes and
call-target category summaries; this is not a source code port.
"""
from __future__ import annotations
import collections,hashlib,json,pathlib,re,subprocess,sys

def command(argv,timeout=90):
    r=subprocess.run(argv,text=True,stdout=subprocess.PIPE,stderr=subprocess.PIPE,timeout=timeout)
    if r.returncode:raise RuntimeError((argv[:2],r.stderr[:400]))
    return r.stdout
def digest(path):
    h=hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda:f.read(1024*1024),b""):h.update(chunk)
    return h.hexdigest()
def main():
    assert len(sys.argv)==3,"usage: MATLAB_ROOT OUTPUT_JSON"
    root=pathlib.Path(sys.argv[1]).resolve()
    lib=root/"bin/glnxa64/libmwmathspec.so"
    assert lib.is_file()
    # The publicly available ABI labels only, not proprietary code.
    data=command(["nm","-D","-S","--defined-only","-C",str(lib)])
    symbol_regex=re.compile(r"^([0-9a-fA-F]+)\s+([0-9a-fA-F]+)\s+([A-Za-z])\s+(.+)$")
    rows=[]
    for line in data.splitlines():
        match=symbol_regex.match(line)
        if match:
            address,size,kind,name=match.groups()
            rows.append({"address":int(address,16),"size":int(size,16),
                         "kind":kind,"name":name})
    mathspec=[r for r in rows if r["name"].startswith("mathspec::")]
    beta=[r for r in rows if r["name"].startswith("mathspec::betainc(")]
    assert len(beta)==1,("need unique real betainc mathematical entrypoint",beta)
    symbol=beta[0]
    begin=symbol["address"]
    end=begin+symbol["size"]
    assert symbol["size"]>0
    dis=command(["objdump","--no-show-raw-insn","-d","-M","intel",
                 "--start-address",hex(begin),"--stop-address",hex(end),str(lib)],timeout=90)
    instr=[]
    # Never persist assembly text or operands; only aggregate op classification.
    for line in dis.splitlines():
        match=re.match(r"\s*([0-9a-fA-F]+):\s+([A-Za-z][\w.]*)\s*(.*?)\s*$",line)
        if not match:continue
        addr=int(match.group(1),16)
        opcode=match.group(2)
        operand=match.group(3)
        if not (begin<=addr<end):continue
        instr.append((addr,opcode,operand))
    assert len(instr)>100,("too few decoded instructions",len(instr))
    hist=collections.Counter(op for _,op,_ in instr)
    calls=[]
    for addr,opcode,operand in instr:
        if opcode.startswith("call"):
            label=operand.split("<",1)[1].split(">",1)[0] if "<" in operand else ""
            if label:
                label=label.split("@",1)[0]
            else:
                label="UNNAMED_LOCAL_TARGET"
            calls.append(label)
    categories={
       "add_sub_scalar_double":sum(n for k,n in hist.items() if re.match(r"^(?:v?addsd|v?subsd)$",k)),
       "multiply_scalar_double":sum(n for k,n in hist.items() if re.match(r"^v?mulsd$",k)),
       "divide_scalar_double":sum(n for k,n in hist.items() if re.match(r"^v?divsd$",k)),
       "sqrt_scalar_double":sum(n for k,n in hist.items() if re.match(r"^v?sqrtsd$",k)),
       "FMA":sum(n for k,n in hist.items() if re.search(r"fmadd|fmsub|fnmadd|fnmsub",k)),
       "compare":sum(n for k,n in hist.items() if "cmp" in k or "comisd" in k or k.startswith("test")),
       "conditional_branches":sum(n for k,n in hist.items() if k.startswith("j") and k not in ("jmp","jmpq")),
       "unconditional_jumps":sum(n for k,n in hist.items() if k.startswith("jmp")),
       "calls":sum(n for k,n in hist.items() if k.startswith("call")),
    }
    report={
        "classification":"R2026B_INSTALLED_MATHSPEC_NATIVE_NUMERICAL_OPERATION_TOPOLOGY_METADATA",
        "original_binary_not_distributed":True,
        "vendor_assembly_not_stored":True,
        "license_bypassed":False,
        "not_general_pure_Rust_parity":True,
        "not_sealed_source_unseen_V12":True,
        "installed_library_sha256":digest(lib),
        "mathspec_exported_symbols_count":len(mathspec),
        "mathspec_exported_symbol_names":[{"name":r["name"],"size_bytes":r["size"]}
                                           for r in mathspec[:100]],
        "betainc_entrypoint":{"public_abi_symbol_name":symbol["name"],
                              "symbol_size_bytes":symbol["size"],
                              "instruction_count":len(instr),
                              "instruction_categories":categories,
                              "unique_named_call_targets":sorted(set(calls))[:50],
                              "named_call_target_frequencies":dict(sorted(collections.Counter(calls).items()))},
    }
    out=pathlib.Path(sys.argv[2]);out.parent.mkdir(parents=True,exist_ok=True)
    out.write_text(json.dumps(report,indent=2,sort_keys=True)+"\n")
    print("NATIVE_MATHSPEC_LIBRARY_SHA",report["installed_library_sha256"])
    print("EXPORT_COUNT",len(mathspec),"BETA_SIZE",symbol["size"],"INSTRUCTIONS",len(instr))
    print("OPCODE_SUMMARY",json.dumps(categories,sort_keys=True))
    print("CALL_TARGET_NAMES_ONLY",json.dumps(report["betainc_entrypoint"]["named_call_target_frequencies"],sort_keys=True))
    print("NATIVE_METADATA_SHA",digest(out))
    print("SOURCE_NUMERICAL_PARITY_NOT_CERTIFIED")
if __name__=="__main__":main()
