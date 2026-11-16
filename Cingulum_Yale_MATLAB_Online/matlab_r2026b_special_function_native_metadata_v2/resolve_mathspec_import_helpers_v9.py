#!/usr/bin/env python3
"""Map previously discovered original mathspec call target addresses to symbol names.

SHA-pinned, original R2026b installed library only. No vendor code or
numerical outputs extracted, disassembled text is transient in RAM only.
"""
from __future__ import annotations
import hashlib
import json
import pathlib
import re
import subprocess
import sys

SHA = "625bc659a790963d52dca039c66bcbde68c319caba37f89b85dd977c6a3be848"
# Prior source-authenticated R2026b original V5/V7 *target addresses*, not
# any original instruction bytes or inferred proprietary implementation.
TARGETS = [0x629a0, 0x62a20, 0x62a40, 0x632d0, 0x632e0,
           0x68ee0, 0x8cb20, 0x8f1e0, 0x9d750, 0xea900]

def run(cmd):
    p = subprocess.run(cmd, text=True, capture_output=True, timeout=120)
    if p.returncode:
        raise RuntimeError(f"symbol metadata command failed: {cmd[0]}")
    return p.stdout

def sha(path):
    h=hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda:f.read(1024*1024),b""):
            h.update(chunk)
    return h.hexdigest()

def main():
    if len(sys.argv)!=3:
        raise SystemExit("usage: resolve_mathspec_import_helpers_v9.py MATLAB_ROOT OUTPUT_JSON")
    lib=pathlib.Path(sys.argv[1])/"bin/glnxa64/libmwmathspec.so"
    assert lib.is_file() and sha(lib)==SHA,"original runtime SHA mismatch"
    # Identify symbol names from dynamic symbol, relocation and PLT metadata.
    # Never persist text disassembly to disk or emit raw instructions.
    dyn=run(["nm","-D","-C",str(lib)])
    imports=sorted({m.group(1) for line in dyn.splitlines()
                    if (m:=re.search(r"\sU\s+([\w.:@]+)",line))})
    sections=run(["readelf","-W","-S",str(lib)])
    plt_sections=[]
    for line in sections.splitlines():
        m=re.search(r"\]\s+(\.plt(?:\.sec|\.got)?)\s+PROGBITS",line)
        if m and m.group(1) not in plt_sections:
            plt_sections.append(m.group(1))
    plt_map={}
    for sec in plt_sections:
        try:
            decoded=run(["objdump","-d","-j",sec,str(lib)])
        except RuntimeError:
            continue
        for line in decoded.splitlines():
            m=re.match(r"^([0-9a-fA-F]+)\s+<([^>]+)>:",line)
            if m:
                addr=int(m.group(1),16)
                # Only report the names of specifically requested call targets,
                # not the surrounding vendor instruction listing.
                if addr in TARGETS:
                    plt_map[hex(addr)]=m.group(2)
    # Dynamic exported names whose exact start address equals a previously
    # archived call target, in case it does not belong to an import PLT.
    syms=run(["nm","-D","--defined-only","-C",str(lib)])
    exact={}
    for line in syms.splitlines():
        m=re.match(r"^([0-9a-fA-F]+)\s+(?:[0-9a-fA-F]+\s+)?[A-Za-z]\s+(.+)$",line)
        if m:
            addr=int(m.group(1),16)
            if addr in TARGETS:
                exact[hex(addr)]=m.group(2)
    resolved={}
    for a in TARGETS:
        key=hex(a)
        resolved[key]={
          "name_from_plt":plt_map.get(key),
          "name_from_exact_export":exact.get(key),
          "classification":("plt_import" if key in plt_map else
                            "exact_dynamic_export" if key in exact else
                            "non_exported_or_not_mapped")
        }
    report={
      "classification":"ORIGINAL_R2026B_MATHSPEC_IMPORT_CALL_TARGET_SYMBOLS_ONLY_V9",
      "vendor_library_sha256":SHA,
      "import_names_present":{name:(name in imports)
             for name in ["log@GLIBC_2.2.5","pow@GLIBC_2.2.5","sqrt@GLIBC_2.2.5"]},
      "dynamic_symbol_name_metadata_only":True,
      "vendor_assembly_or_math_outputs_published":False,
      "original_numerical_runtime_copied_into_Rust":False,
      "independent_pure_Rust_exactness":"NOT_CERTIFIED",
      "source_unseen_V12":"NOT_GENERATED",
      "call_target_resolution":resolved
    }
    out=pathlib.Path(sys.argv[2]);out.write_text(json.dumps(report,sort_keys=True,indent=2)+"\n")
    print("ORIGINAL_R2026B_SYMBOL_NAMES_ONLY",[(x,v["name_from_plt"]) for x,v in resolved.items()])
    print("REPORT_SHA256",sha(out))
if __name__=="__main__":
    main()
