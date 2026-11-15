#!/usr/bin/env python3
"""Inspect ONLY installed R2026b symbol metadata, dependency names and M-file call names.

No vendor proprietary object file or source contents are copied or published.
This script does not execute, patch, disassemble, bypass licensing for, or
extract numerical implementations. Its purpose is to choose a lawful native
implementation-level research plan.
"""
from __future__ import annotations
import hashlib,json,os,pathlib,re,subprocess,sys
def cmd(argv,timeout=20):
    result=subprocess.run(argv,text=True,capture_output=True,timeout=timeout,check=False)
    return result.returncode,result.stdout
def sha256(path):
    h=hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda:f.read(1024*1024),b""):h.update(chunk)
    return h.hexdigest()
def matches(lines,patterns,max_count=80):
    keys=[re.compile(x,re.I) for x in patterns]
    return sorted(set(x.strip() for x in lines if any(k.search(x) for k in keys)))[:max_count]
def main():
    assert len(sys.argv)==3,"usage: install_ROOT OUT_REPORT"
    root=pathlib.Path(sys.argv[1]).resolve()
    output=pathlib.Path(sys.argv[2]).resolve()
    lib=root/"bin/glnxa64/libmwmathspec.so"
    assert lib.is_file(),lib
    rc,nm=cmd(["nm","-D","--defined-only","-C",str(lib)],timeout=40)
    assert rc==0
    symbols=nm.splitlines()
    queries=[r"(?:^|::)(?:betainc|betaincinv|gammaln|gamma)(?:::|\(|\s|$)",
             r"(?:ibeta|incbet|bratio|bfrac|bpser|basym|bgrat|bup|lanczos|loggamma|lgamma)"]
    present=matches(symbols,queries,100)
    filtered=[s for s in present if not any(u in s for u in ("mxErrMsgId<","Exception<","Exception(","exception","vtable","typeinfo","allocator","std::"))]
    rc,section=cmd(["readelf","-SW",str(lib)])
    assert rc==0
    rc,needed=cmd(["readelf","-d",str(lib)])
    assert rc==0
    needed_libraries=sorted(set(re.findall(r"\(NEEDED\).*?\[(.*?)\]",needed)))
    rc,undef=cmd(["nm","-D","--undefined-only","-C",str(lib)],timeout=40)
    assert rc==0
    relevant_undef=matches(undef.splitlines(),[r"(?:lgamma|tgamma|pow|exp|log|erfc|gamma|beta|sqrt|atan)(?:\W|$)"],40)
    files={
       "stats/stats/tcdf.m":root/"toolbox/stats/stats/tcdf.m",
       "matlab/specfun/betaln.m":root/"toolbox/matlab/specfun/betaln.m"
    }
    mfiles={}
    for name,path in files.items():
       if not path.is_file():
          mfiles[name]={"exists":False};continue
       source=path.read_text(encoding="utf-8",errors="replace").splitlines()
       # Only function names and matching source LINE NUMBERS; no MATLAB code.
       query=["betainc","betaln","gammaln","gamma","erfc","normcdf","betacdf","tcdf","stdtr","log1p"]
       calls={term:[i for i,line in enumerate(source,1)
          if re.search(r"\b"+term+r"\s*\(",line) and
              not line.lstrip().startswith("%")]
          for term in query}
       mfiles[name]={"exists":True,"line_count":len(source),
                     "sha256":sha256(path),
                     "call_sites":{k:v for k,v in calls.items() if v}}
    result={
       "classification":"GENUINE_MATHWORKS_R2026B_INSTALLED_BINARY_AND_MFILE_METADATA_ONLY",
       "numerical_oracle_outputs":"NONE",
       "vendor_binary_or_Mfile_source_bytes_copied":False,
       "compiled_vendor_code_executed_by_native_Rust":False,
       "not_lawful_to_redistribute_vendor_binaries":True,
       "Matlab_Coder_license_granted":False,
       "library_filename":lib.name,
       "installed_library_sha256":sha256(lib),
       "library_size_bytes":lib.stat().st_size,
       "static_symtab_present":".symtab" in section,
       "dynamic_symbol_lines":len(symbols),
       "defined_relevant_dynamic_symbol_lines":len(present),
       "candidate_numerical_export_lines":filtered[:80],
       "candidate_numerical_export_count":len(filtered),
       "dynamic_library_dependencies":needed_libraries,
       "external_numerical_call_symbol_lines":relevant_undef,
       "Mfile_call_sites_only":mfiles
    }
    output.parent.mkdir(parents=True,exist_ok=True)
    output.write_text(json.dumps(result,sort_keys=True,indent=2)+"\n")
    print("LIBRARY",lib.name,"SHA256",result["installed_library_sha256"])
    print("SYMBOL_TABLE",result["static_symtab_present"],"DYNAMIC_SYMBOL_COUNT",len(symbols))
    print("VENDOR_NUMERIC_ENTRYPOINT_CANDIDATES",len(filtered))
    for s in filtered[:50]:print("CANDIDATE",s)
    print("RELEVANT_EXTERNAL_MATH_CALLS")
    for s in relevant_undef:print("EXTERNAL",s)
    for name,data in mfiles.items():print("MFILE",name,json.dumps(data,sort_keys=True))
    print("METADATA_REPORT_SHA256",sha256(output))
    print("NOT_PROOF_OF_EXACT_RUST_PARITY_AND_NOT_ALGORITHM_COPY")
if __name__=="__main__":main()
