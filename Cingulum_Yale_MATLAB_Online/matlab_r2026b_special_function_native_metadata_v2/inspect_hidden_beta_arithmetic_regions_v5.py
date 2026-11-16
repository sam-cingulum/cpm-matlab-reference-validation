#!/usr/bin/env python3
"""Quantify private numerical code-region structure without copying code.

Uses V4 source-observed branch destination and a SHA-pinned genuine MathWorks
R2026b mathspec installation. Does not expose instruction bytes, operands,
numerical constants, implementation source or vendor runtime output.
"""
from __future__ import annotations
import collections,hashlib,json,pathlib,re,subprocess,sys

PINNED="625bc659a790963d52dca039c66bcbde68c319caba37f89b85dd977c6a3be848"
def run(cmd):
    p=subprocess.run(cmd,text=True,capture_output=True,check=False,timeout=75)
    if p.returncode: raise RuntimeError(p.stderr[:1200])
    return p.stdout
def sha(p):
    h=hashlib.sha256()
    with p.open("rb") as f:
        for x in iter(lambda:f.read(1024*1024),b""):h.update(x)
    return h.hexdigest()
def decode_span(lib,start,end):
    data=run(["objdump","-d","--no-show-raw-insn","-M","intel",
             "--start-address",hex(start),"--stop-address",hex(end),str(lib)])
    rows=[]
    for line in data.splitlines():
        m=re.match(r"\s*([0-9a-fA-F]+):\s+([A-Za-z][\w.]*)\s*(.*?)\s*$",line)
        if m:
            addr=int(m.group(1),16)
            if start<=addr<end:rows.append((addr,m.group(2),m.group(3)))
    return rows
def characterize(rows,origin,limit):
    hist=collections.Counter(m for _,m,_ in rows)
    by_group={
        "binary64_add_sub":sum(n for x,n in hist.items() if re.search(r"^(?:v?addsd|v?subsd)$",x)),
        "binary64_mul":sum(n for x,n in hist.items() if re.search(r"^v?mulsd$",x)),
        "binary64_div":sum(n for x,n in hist.items() if re.search(r"^v?divsd$",x)),
        "binary64_sqrt":sum(n for x,n in hist.items() if re.search(r"^v?sqrtsd$",x)),
        "FMA":sum(n for x,n in hist.items() if re.search(r"fmadd|fmsub|fnmadd|fnmsub",x)),
        "float_compare":sum(n for x,n in hist.items() if "comisd" in x or "comiss" in x),
        "conditional_branches":sum(n for x,n in hist.items() if x.startswith("j") and not x.startswith("jmp")),
        "direct_calls":sum(n for x,n in hist.items() if x.startswith("call")),
        "unconditional_jumps":sum(n for x,n in hist.items() if x.startswith("jmp")),
        "returns":sum(n for x,n in hist.items() if x.startswith("ret")),
    }
    branches=collections.Counter()
    calltargets=collections.Counter()
    for loc,mn,op in rows:
        if not (mn.startswith("call") or mn.startswith("jmp")): continue
        m=re.match(r"^([0-9a-fA-F]+)(?:\s|$)",op)
        if not m:continue
        dst=int(m.group(1),16)
        kind="CALL" if mn.startswith("call") else "TAIL_OR_NORMAL_JMP"
        calltargets[(kind,hex(dst))]+=1
        branches[(kind,"inside" if origin<=dst<limit else "outside")]+=1
    return {"instruction_count":len(rows),"arithmetic_and_control_counts":by_group,
            "control_transfer_domain_counts":{
                k+"_"+loc:n for (k,loc),n in sorted(branches.items())},
            "distinct_target_counts":[
                {"category":kind,"relative_target":dst,"count":n}
                 for (kind,dst),n in sorted(calltargets.items(),key=lambda kv:(-kv[1],kv[0]))[:90]
            ]}
def main():
    assert len(sys.argv)==3
    root=pathlib.Path(sys.argv[1])
    lib=root/"bin/glnxa64/libmwmathspec.so"
    assert lib.is_file() and sha(lib)==PINNED,"original R2026b library SHA changed: do not reuse observations"
    sym=run(["nm","-D","-S","--defined-only","-C",str(lib)])
    targets={}
    for line in sym.splitlines():
        m=re.match(r"^([0-9a-fA-F]+)\s+([0-9a-fA-F]+)\s+[A-Za-z]\s+(.*)$",line)
        if not m:continue
        name=m.group(3)
        if name in ("mathspec::betainc(double, double, double, mathspec::TailType)",
                    "mathspec::gammaln(double)"):
            targets[name]=(int(m.group(1),16),int(m.group(2),16))
    assert len(targets)==2
    beta_addr,beta_size=targets["mathspec::betainc(double, double, double, mathspec::TailType)"]
    gamma_addr,gamma_size=targets["mathspec::gammaln(double)"]
    assert beta_addr==0xeb750 and beta_size==146, (hex(beta_addr),beta_size)
    assert gamma_size==5
    hidden=0xeb010  # Original genuine R2026b v4 successful beta path, SHA-pinned.
    assert hidden<beta_addr
    region=decode_span(lib,hidden,beta_addr)
    beta=characterize(region,hidden,beta_addr)
    assert beta["instruction_count"]>30
    gamma=decode_span(lib,gamma_addr,gamma_addr+gamma_size)
    gammainfo=characterize(gamma,gamma_addr,gamma_addr+gamma_size)
    report={
      "classification":"R2026B_SHA_PINNED_HIDDEN_BETA_CODE_REGION_ARITHMETIC_TOPOLOGY_METADATA_V5",
      "original_library_sha256":PINNED,
      "original_vendor_binary_or_assembly_distributed":False,
      "scientific_kernel_numerical_outputs_fed_to_Rust":False,
      "complete_function_boundaries_verified":False,
      "analysis_region_begins_at_observed_v4_hidden_normal_path_target":hex(hidden),
      "analysis_region_ends_at_public_beta_export":hex(beta_addr),
      "analysis_region_bytes":beta_addr-hidden,
      "beta_possible_hidden_algorithm_region":beta,
      "gamma_forwarding_export":gammainfo,
      "numerical_parity_status":"NOT_CERTIFIED",
      "source_unseen_V12":"NOT_GENERATED"
    }
    out=pathlib.Path(sys.argv[2]);out.parent.mkdir(parents=True,exist_ok=True)
    out.write_text(json.dumps(report,indent=2,sort_keys=True)+"\n")
    print("BETA_HIDDEN_REGION",hex(hidden),"TO",hex(beta_addr),"BYTES",beta_addr-hidden)
    print("BETA_OPCODE_TOPOLOGY",json.dumps(beta["arithmetic_and_control_counts"],sort_keys=True))
    print("BETA_BRANCH_TARGETS",json.dumps(beta["distinct_target_counts"][:35],sort_keys=True))
    print("GAMMA_FORWARDING",json.dumps(gammainfo,sort_keys=True))
    print("REPORT_SHA",sha(out))
    print("NO_PROPRIETARY_CODE_RETURNED; EXACT_RUST_BINARY64_STILL_UNPROVEN")
if __name__=="__main__":main()
