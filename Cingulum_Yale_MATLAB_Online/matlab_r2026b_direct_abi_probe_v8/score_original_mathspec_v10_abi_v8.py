#!/usr/bin/env python3
"""Original R2026b source-disclosed V10 native library ABI parity RESEARCH.

This is an external Oracle-versus-Oracle diagnostic on the SAME licensed
MATLAB runner. It neither compiles nor links Cingulum Rust to MathWorks,
exports vendor binaries or stores numerical MATLAB source outputs in repo.
"""
from __future__ import annotations
import argparse,hashlib,json,pathlib,sys
ROOT=pathlib.Path(__file__).resolve().parent
V10=ROOT.parent/"matlab_beta_mean_switch_v10_disclosed/input.json"
INPUT_SHA="ed1b3af2b864241caa9719a3dc8ceb2df670c0a9bf426cf741d5959d60adedc5"
def sha(blob):return hashlib.sha256(blob).hexdigest()
def load():
    b=V10.read_bytes()
    assert sha(b)==INPUT_SHA,(sha(b),INPUT_SHA)
    d=json.loads(b)
    assert d["source_unseen_V12"]=="NOT_GENERATED"
    assert not d["original_MATLAB_numeric_data_supplied"]
    assert d["gamma_count"]==60 and d["beta_count"]==2812
    return d
def inputs():
    d=load()
    out=[]
    for a in d["gamma"]:out.append("G "+a["x_hex"]+"\n")
    for a in d["beta"]:
        out.append("B "+" ".join(a[k] for k in ("x_hex","a_hex","b_hex"))+"\n")
    where=ROOT/"abi_input_v8.txt"
    where.write_text("".join(out))
    print("SOURCE_V10_INPUT_SHA",INPUT_SHA)
    print("ABI_V10_INPUT_COUNT",len(out))
    print("ABI_V10_INPUT_FILE_SHA",sha(where.read_bytes()))
def score():
    d=load()
    lhs=(ROOT/"original_v10_gamma_beta_hex_v8.txt").read_text().splitlines()
    rhs=(ROOT/"abi_v10_gamma_beta_hex_v8.txt").read_text().splitlines()
    assert len(lhs)==len(rhs)==d["gamma_count"]+d["beta_count"],(len(lhs),len(rhs))
    gamm=0; beta=0;cases={}
    matches={
       "tail0_lower":0,"tail1_upper":0,"tail0_upper":0,"tail1_lower":0,
       "tail0_lower_tail1_upper_both":0,
       "tail1_lower_tail0_upper_both":0
    }
    for i,(l,r) in enumerate(zip(lhs,rhs)):
        a=l.split();b=r.split()
        if i<60:
            assert a[0]==b[0]=="G" and len(a)==len(b)==3
            assert a[1]==b[1]==d["gamma"][i]["x_hex"]
            gamm+=a[2]==b[2]
        else:
            j=i-60
            expected=d["beta"][j]
            assert a[0]==b[0]=="B" and len(a)==len(b)==6
            assert a[1:4]==b[1:4]==[expected[k] for k in ("x_hex","a_hex","b_hex")]
            lo0=b[4]==a[4];up1=b[5]==a[5]
            up0=b[4]==a[5];lo1=b[5]==a[4]
            matches["tail0_lower"]+=lo0
            matches["tail1_upper"]+=up1
            matches["tail0_upper"]+=up0
            matches["tail1_lower"]+=lo1
            matches["tail0_lower_tail1_upper_both"]+=lo0 and up1
            matches["tail1_lower_tail0_upper_both"]+=lo1 and up0
    # One global enum semantic mapping, never case-specific polarity selection.
    normal=matches["tail0_lower_tail1_upper_both"]
    swapped=matches["tail1_lower_tail0_upper_both"]
    mapping="0=lower,1=upper" if normal>=swapped else "0=upper,1=lower"
    best=max(normal,swapped)
    report={
       "classification":"MATLAB_R2026B_V10_SOURCE_DISCLOSED_SAME_HOST_ORIGINAL_MATHSPEC_ABI_ORACLE_AGREEMENT_RESEARCH_ONLY",
       "genuine_MATLAB_runtime_source":"R2026b",
       "original_disclosed_V10_input_sha256":INPUT_SHA,
       "original_matlab_numeric_results_sha256":sha((ROOT/"original_v10_gamma_beta_hex_v8.txt").read_bytes()),
       "research_original_mathspec_abi_numeric_results_sha256":sha((ROOT/"abi_v10_gamma_beta_hex_v8.txt").read_bytes()),
       "sample_count_gamma":60,
       "original_mathspec_abi_gamma_exact":gamm,
       "sample_count_beta":2812,
       "original_mathspec_abi_beta_tail_matches":matches,
       "global_enum_orientation_diagnostic":mapping,
       "best_global_orientation_full_beta_pairs_exact":best,
       "matlab_vendor_original_numeric_outputs_supplied_to_independently_compiled_Rust":False,
       "mathworks_vendor_library_linked_by_independent_Rust":False,
       "original_vendor_library_binary_copied":False,
       "source_unseen_V12":"NOT_GENERATED",
       "independent_pure_rust_matlab_parity_certified":False,
       "research_abi_gamma_all_strict":gamm==60,
       "research_abi_beta_all_strict":best==2812,
       "original_17_returned_robustfit_stats_certified":False,
       "original_Yale_P1_P9_certified":False
    }
    dest=ROOT/"comparison_summary_v8.json"
    dest.write_text(json.dumps(report,sort_keys=True,indent=2)+"\n")
    print("GENUINE_MATLAB_R2026B_ABI_GAMMA_EXACT",gamm,"/60")
    print("GENUINE_MATLAB_R2026B_ABI_BETA_PAIR_EXACT",best,"/2812")
    print("BETA_GLOBAL_TAIL_ENUM",mapping)
    print("BETA_ALL_BITWISE_MATCH_COMPARISON",matches)
    print("RESEARCH_SUMMARY_SHA256",sha(dest.read_bytes()))
    print("INDEPENDENT_PURE_RUST_FULL_MATLAB_PARITY=OPEN; SEALED_V12=NOT_GENERATED")
def main():
    assert len(sys.argv)==2
    if sys.argv[1]=="--prepare":inputs()
    elif sys.argv[1]=="--score":score()
    else:raise SystemExit("Need --prepare or --score")
if __name__=="__main__":main()
