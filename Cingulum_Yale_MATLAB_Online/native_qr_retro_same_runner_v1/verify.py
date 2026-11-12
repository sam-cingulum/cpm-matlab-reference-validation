#!/usr/bin/env python3
"""Retrospective same-run Rust and MathWorks R2026b original QR comparison.
The original 48 source outputs have previously been disclosed, so this does
NOT create new prospective evidence. No proprietary code is accessed.
"""
from __future__ import annotations
import argparse,hashlib,json,pathlib,struct,sys
B=pathlib.Path(__file__).resolve().parent
ROOT=B.parent
INPUT=ROOT/"robustfit_raw_full_source_unseen_v1"/"input.json"
MANIFEST=ROOT/"robustfit_raw_full_source_unseen_v1"/"manifest.json"
NUM=48
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def require(x,msg):
 if not x:raise AssertionError(msg)
def data():
 m=json.loads(MANIFEST.read_text());d=json.loads(INPUT.read_text())
 require(sha(INPUT)==m["input_sha256"],"frozen historical input changed")
 require(len(d["cases"])==NUM,"48 originals required")
 require(d["experiment_id"]==m["experiment_id"],"original experiment identifier changed")
 return d
def encode(v):return struct.pack(">d",float(v)).hex()
def export():
 d=data()
 p=B/"raw_x_hex.tsv"
 require(not p.exists(),"historical raw x already generated")
 lines=[]
 for c in d["cases"]:
  require(c["n"]==len(c["x"])==len(c["y"]),"raw case length mismatch")
  lines.append(c["id"]+"\t"+",".join(encode(v) for v in c["x"]))
 p.write_text("\n".join(lines)+"\n")
 print("RAW_X_FROM_FROZEN_INPUT_ONLY",len(lines),sha(p))
def compare():
 d=data()
 o=json.loads((B/"original_same_runner.json").read_text())
 require(o["release"]=="2026b" and o["case_count"]==48,"genuine source release/cases mismatch")
 require(o["source_original_unmodified"] and o["native_executed_before_original"],"original source provenance")
 require(not o["source_unseen_prospective"],"this is historical, not prospective")
 require(o["max_threads"]==1 and o["mkl_cbwr"]=="COMPATIBLE","numeric profile not controlled")
 require(o["github_sha"] and o["github_run_id"],"missing CI execution identity")
 require(len(o["records"])==48,"original records missing")
 raw=(B/"raw_x_hex.tsv").read_text().splitlines()
 native=(B/"native_r_hex.tsv").read_text().splitlines()
 require(len(raw)==len(native)==48,"raw/native count")
 positions=[0]*4;exact_matrix=0;correct_pivot=0;original_qr_exact=0;input_exact=0
 deviations=[]
 for c,ref,rline,nline in zip(d["cases"],o["records"],raw,native):
  require(c["id"]==ref["id"] and c["n"]==ref["n"],"source case mismatch")
  ri,rx=rline.split("\t",1)
  ni,np,nr=nline.split("\t",2)
  require(ri==ni==ref["id"],"native case mismatch")
  hx=rx.split(",")
  require(len(hx)==c["n"] and len(ref["x_hex"])==c["n"],"missing raw input hex")
  require(hx==[encode(x) for x in c["x"]],"Rust source x transport changed")
  input_exact+=int(hx==[s.lower() for s in ref["x_hex"]])
  require(all(len(x)==16 for x in hx+ref["source_R_hex"]+nr.split(",")),"bad binary64 hex")
  predicted=nr.split(",");truth=[s.lower() for s in ref["source_R_hex"]]
  require(len(predicted)==len(truth)==4,"full QR required")
  require(ref["qr_api_R_hex"]==ref["source_R_hex"],"original source/API mismatch")
  original_qr_exact+=int(ref["original_equals_MATLAB_QR_all_bits"])
  bits=[a==b for a,b in zip(predicted,truth)]
  exact_matrix+=int(all(bits))
  for j,v in enumerate(bits):positions[j]+=int(v)
  piv=[int(s) for s in np.split(",")]
  require(len(piv)==2 and sorted(piv)==[1,2],"invalid native permutation")
  correct_pivot+=int(piv==ref["pivot"])
  deviations.append(dict(id=c["id"],n=c["n"],exact_bits=sum(bits),per_entry=bits,
                         exact_whole=all(bits),pivot_equal=(piv==ref["pivot"])))
 require(input_exact==48,"Rust/MATLAB raw decoded x mismatch")
 require(original_qr_exact==48,"MathWorks robustfit vs same-run QR mismatch")
 require(correct_pivot==48,"Rust pivot orientation mismatch")
 result=dict(status="RETROSPECTIVE_48_ALREADY_DISCLOSED_NOT_PROSPECTIVE",
  source_original="genuine unchanged MATLAB R2026b robustfit",raw_case_count=48,
  source_run=o["github_run_id"],source_git_sha=o["github_sha"],
  runner_cpu=o["cpu"],release=o["matlab_version"],
  native_rust_compiled=True,source_free_native_R=True,
  same_runner_original_and_native=True,
  matlab_exact_Rust_transport_cases=input_exact,
  robustfit_equals_MATLAB_qr_complete_cases=original_qr_exact,
  exact_pivots=correct_pivot,full_R_exact=exact_matrix,
  exact_R_elements=sum(positions),total_R_elements=192,
  per_R_element_columnmajor_exact=positions,
  native_source_sha256=sha(B/"standalone_qr_probe.rs"),
  native_executable_sha256=sha(B/"native_qr_executable"),
  native_predictions_sha256=sha(B/"native_r_hex.tsv"),
  original_report_sha256=sha(B/"original_same_runner.json"),
  prospectively_certified_native_binary64=False,
  original_Yale_OHBM_option3_full_pipeline_certified=False,
  cases=deviations)
 p=B/"retrospective_same_runner_verdict.json"
 require(not p.exists(),"immutable evidence file exists")
 p.write_text(json.dumps(result,indent=2,sort_keys=True)+"\n")
 print("GENUINE_MATLAB_NATIVE_RUST_SAME_RUNNER_RETROSPECTIVE",result["exact_R_elements"],"/192 R bits; full cases",result["full_R_exact"],"/48")
 print("NATIVE_RUST_PIVOTS",result["exact_pivots"],"/48")
 print("NUMERIC_PROFILE_CPU",o["cpu"])
 print("NO_PROSPECTIVE_NATIVE_OR_END_TO_END_CERTIFICATION")
def main():
 ap=argparse.ArgumentParser();ap.add_argument("action",choices=["export","compare"])
 a=ap.parse_args()
 try:{"export":export,"compare":compare}[a.action]()
 except (AssertionError,KeyError,ValueError) as e:
  print("FAIL_CLOSED",str(e),file=sys.stderr);raise SystemExit(1) from e
if __name__=="__main__":main()
