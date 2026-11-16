#!/usr/bin/env python3
"""Strict external source-disclosed R2026b vendor ABI inference diagnostic.

Independent Rust supplies t and dfe. MathWorks original source provides p
ONLY to this external test and never to native Rust. MATLAB original and
unsupported-but-authorized vendor ABI execute on the same R2026b runner.
Tests 960 distinct coefficients / 480 fits plus archived dual repeats.
"""
from __future__ import annotations
import gzip,hashlib,json,math,pathlib,struct,sys,collections
ROOT=pathlib.Path(__file__).resolve().parent
FROZEN_SHA="3a6ba40a3378f629bfeac22bade20c6f4fc19649327eea992e4430a72b931229"
SOURCE_SHA="84dbb7581304b38e59930985efb47ae26a150cc0cab0aff4974091311fa342a5"
BASE=ROOT.parent/"matlab_v11_disclosed_student_t_stages/source_runs/43527737601"
ORIGINAL=BASE/"original_v11_disclosed_student_t_stages.json.gz"
def sha(b):return hashlib.sha256(b).hexdigest()
def decode(b):return struct.unpack(">d",bytes.fromhex(b))[0]
def load_native():
    raw=(ROOT/"frozen_v11_independent_rust_t_dfe_input.json").read_bytes()
    assert sha(raw)==FROZEN_SHA,sha(raw)
    obj=json.loads(raw)
    assert obj["raw_case_count"]==480 and obj["coefficient_count"]==960
    assert not obj["original_MATLAB_reference_numeric_values_used_to_generate"]
    return obj
def source_original():
    raw=gzip.decompress(ORIGINAL.read_bytes())
    assert sha(raw)==SOURCE_SHA,sha(raw)
    obj=json.loads(raw)
    assert obj["release"]=="2026b" and obj["original_repetitions"]==2
    assert len(obj["rows"])==1920
    out=collections.defaultdict(list)
    for x in obj["rows"]:
        out[(x["id"],int(x["coef_index"]))].append(x)
    assert len(out)==960
    return out
def prepare():
    native=load_native()
    lines=[]
    for case in native["rows"]:
        for j,t in enumerate(case["t_hex"],1):
            lines.append("T "+" ".join((case["id"],str(j),t,case["dfe_hex"]))+"\n")
    output=ROOT/"v11_rust_t_dfe_abi_input.txt"
    output.write_text("".join(lines))
    assert len(lines)==960
    print("RUST_V11_SOURCE_DISCLOSED_T_DFE_INPUT_960_SHA",sha(output.read_bytes()))
def read_results(p, expected_fields:int):
    rows={}
    for text in p.read_text().splitlines():
        a=text.split()
        assert len(a)==expected_fields and a[0]=="T",(p,a)
        key=(a[1],int(a[2]))
        assert key not in rows
        rows[key]=a
    assert len(rows)==960,(p,len(rows))
    return rows
def score():
    native=load_native()
    original=source_original()
    same=read_results(ROOT/"original_v11_p_from_rust_t_v9.txt",6)
    abi=read_results(ROOT/"abi_v11_p_from_rust_t_v9.txt",8)
    count=collections.Counter()
    whole_fit={c["id"]:[] for c in native["rows"]}
    for case in native["rows"]:
        for j,t in enumerate(case["t_hex"],1):
            key=(case["id"],j)
            a=same[key];b=abi[key];refs=original[key]
            assert len(refs)==2
            assert a[3]==b[3]==t and a[4]==b[4]==case["dfe_hex"]
            assert all(r["source_t_hex"]==t and r["source_dfe_hex"]==case["dfe_hex"] for r in refs)
            count["native_rust_t_and_dfe_exact_vs_original_repetition_elements"]+=2
            count["same_host_abi_p_vs_same_host_interpreter_p_exact"]+=(b[5]==a[5])
            lower=b[6];upper=b[7]
            t2=decode(t)**2;df=decode(case["dfe_hex"])
            selected=upper if t2<df else lower
            assert selected==b[5],"C++ ABI branch output must use one global t²<df policy"
            count["beta_upper_branch" if t2<df else "beta_lower_branch"]+=1
            fit_each=[]
            for original_row in refs:
                expected=original_row["source_p_hex"]
                assert expected==(original_row["source_betainc_upper_hex"] if t2<df
                     else original_row["source_betainc_lower_hex"])
                count["same_host_interpreter_p_vs_original_archived_R2026b_p_exact"]+=(a[5]==expected)
                count["ABI_p_vs_archived_original_R2026b_p_exact"]+=(b[5]==expected)
                fit_each.append(b[5]==expected)
            whole_fit[case["id"]].append(all(fit_each))
            count["original_archived_p_elements_checked"]+=2
    count["coefficient_cases"]=960
    count["fits_480_both_coefficients_and_both_repetitions_exact"]+=sum(all(v) for v in whole_fit.values())
    count["whole_fit_repetition_comparisons_exact"]+=2*sum(all(v) for v in whole_fit.values())
    good_same=count["same_host_abi_p_vs_same_host_interpreter_p_exact"]==960
    good_source=count["ABI_p_vs_archived_original_R2026b_p_exact"]==1920
    assert count["native_rust_t_and_dfe_exact_vs_original_repetition_elements"]==1920
    assert count["original_archived_p_elements_checked"]==1920
    report={
      "classification":"SOURCE_DISCLOSED_V11_GENUINE_R2026B_INDEPENDENT_RUST_T_DFE_ORIGINAL_VENDOR_ABI_P_INFERENCE_EXTERNAL_DIAGNOSTIC",
      "source_unseen_V12":"NOT_GENERATED",
      "input_native_rust_SHA":FROZEN_SHA,"original_archived_R2026b_source_SHA":SOURCE_SHA,
      "original_MATLAB_library_called_in_independently_compiled_Rust":False,
      "original_source_numeric_answers_fed_to_independently_compiled_Rust":False,
      "genuine_MATLAB_R2026b_run":True,"vendor_research_rust_independence":"No R2026b MathWorks code or FFI in Rust; C++ is a research-only control",
      "same_host_abi_vs_original_interpreter_p_exact_all":good_same,
      "abi_vs_original_archived_3_AMD_2_repetitions_p_exact_all":good_source,
      "counts":dict(sorted(count.items())),
      "same_host_interpreter_output_SHA":sha((ROOT/"original_v11_p_from_rust_t_v9.txt").read_bytes()),
      "native_abi_original_output_SHA":sha((ROOT/"abi_v11_p_from_rust_t_v9.txt").read_bytes()),
      "original_robustfit_17_returned_fields_certified":False,
      "original_Yale_P1_to_P9_certified":False,
      "independently_compiled_pure_Rust_gammaln_betainc_binary64_parity_certified":False
    }
    output=ROOT/"comparison_summary_v9.json"
    output.write_text(json.dumps(report,sort_keys=True,indent=2)+"\n")
    print("ORIGINAL_V11_RUST_T_DFE_VS_MATLAB",count["native_rust_t_and_dfe_exact_vs_original_repetition_elements"],"/1920")
    print("ORIGINAL_V11_VENDOR_ABI_VS_SAME_HOST_INTERPRETER_P",count["same_host_abi_p_vs_same_host_interpreter_p_exact"],"/960")
    print("ORIGINAL_V11_VENDOR_ABI_VS_ARCHIVED_AMD_ORIGINAL_P",count["ABI_p_vs_archived_original_R2026b_p_exact"],"/1920")
    print("ORIGINAL_V11_VENDOR_ABI_WHOLE_FITS",count["whole_fit_repetition_comparisons_exact"],"/960")
    print("RESEARCH_SUMMARY_SHA256",sha(output.read_bytes()))
    print("PURE_RUST_COMPLETE_ORIGINAL_MATLAB_STATISTICAL_PARITY_OPEN; V12_NOT_GENERATED")
def main():
    assert len(sys.argv)==2
    if sys.argv[1]=="--prepare":prepare()
    elif sys.argv[1]=="--score":score()
    else:raise SystemExit("--prepare or --score")
if __name__=="__main__":main()
