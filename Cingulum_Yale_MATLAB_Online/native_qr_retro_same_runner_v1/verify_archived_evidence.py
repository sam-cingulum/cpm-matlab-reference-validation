#!/usr/bin/env python3
"""Fail-closed archive integrity and independent retrospective bit verifier.

Original inputs and source outputs were disclosed *before* both experiments.
This is NOT prospective original-source-unseen or production Rust certification.
"""
from __future__ import annotations
import hashlib,json,pathlib,struct,sys
BASE=pathlib.Path(__file__).resolve().parent
PUBLIC=BASE.parent/"robustfit_raw_full_source_unseen_v1"
ART=BASE/"evidence"
SHA={
 "original_same_runner_43181373473.json":"7635cf3c78e9d0e5b38e60883206f3d76b52ded7ddbabe8b3a75e1f914c20ca9",
 "retrospective_same_runner_verdict_43181373473.json":"273f952540f126de16dcaff54eaf3397105ee6e6e77f98681441d0022c5f0bfd",
 "native_r_hex_43181373473.tsv":"6183ae5fccdf34e64e4a91ce6bc4138f1723e85ecd744865fca9fa5154aa3dc6",
 "raw_x_hex_43181373473.tsv":"2ef16fb854c961b6302b79bc23420936373160a66ace3f9bad1bc11ae89014f2",
 "matlab_householder_arithmetic_43182539905.json":"27988f5d3d5b780357df4f140d254c4befa5376be96b96ad86a3b74e01ee72ca",
}
def require(x,msg):
 if not x: raise AssertionError(msg)
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def f64hex(x):return struct.pack(">d",x).hex()
def check(artifact_dir=ART):
 for name,expected in SHA.items():
  require(sha(artifact_dir/name)==expected,"AUTHENTIC_ARTIFACT_SHA256_MISMATCH "+name)
 old=json.loads((PUBLIC/"source_result.json").read_text())
 raw=json.loads((PUBLIC/"input.json").read_text())
 new=json.loads((artifact_dir/"original_same_runner_43181373473.json").read_text())
 verdict=json.loads((artifact_dir/"retrospective_same_runner_verdict_43181373473.json").read_text())
 diag=json.loads((artifact_dir/"matlab_householder_arithmetic_43182539905.json").read_text())
 require(sha(PUBLIC/"input.json")=="36f70d7cfd31da808f4c5f61f1127e292597097287a21248782723436f26fa1b","input changed")
 require(sha(PUBLIC/"source_result.json")=="02f4a8c7aba7c3ee65b37bc3873d3a603c06382272a7b8e21075f7a6d933e6b5","original changed")
 require(new["github_run_id"]==verdict["source_run"]=="43181373473","same-run CI identity changed")
 require(diag["github_run_id"]=="43182539905","independent MATLAB numeric experiment changed")
 require(new["mkl_cbwr"]==diag["mkl_cbwr"]=="COMPATIBLE","Matlab compatibility setting changed")
 require(new["max_threads"]==diag["max_threads"]==1,"MATLAB threading changed")
 require(new["source_unseen_prospective"] is False and verdict["prospectively_certified_native_binary64"] is False,"false certification")
 require(old["profile"]["cpu_model"]!=new["cpu"],"two AMD CPU profiles required")
 require(len(raw["cases"])==len(old["records"])==len(new["records"])==len(diag["records"])==48,"missing cases")
 xs=(artifact_dir/"raw_x_hex_43181373473.tsv").read_text().splitlines()
 rs=(artifact_dir/"native_r_hex_43181373473.tsv").read_text().splitlines()
 require(len(xs)==len(rs)==48,"missing native records")
 original_across_cpu=0; complete_matlab=0; exact_native=0;complete_native=0;exact_pivot=0;input_transport=0
 for case,oldsrc,src,nrow,xrow in zip(raw["cases"],old["records"],new["records"],rs,xs):
  require(case["id"]==oldsrc["id"]==src["id"],"source case mapping differs")
  rid,rpivot,rvalue=nrow.split("\t")
  xid,xvalue=xrow.split("\t")
  require(rid==xid==case["id"],"native case ID/order changed")
  expected_x=[f64hex(float(x)) for x in case["x"]]
  require(xvalue.split(",")==expected_x,"raw Rust input materialization changed")
  input_transport+=int(src["x_hex"]==expected_x)
  orig=oldsrc["fields"]["R"]
  recent=src["source_R_hex"]
  require(len(recent)==len(orig)==4,"original R incomplete")
  original_across_cpu+=sum(a==b for a,b in zip(recent,orig))
  complete_matlab+=int(src["original_equals_MATLAB_QR_all_bits"] and src["qr_api_R_hex"]==recent)
  rh=rvalue.split(",")
  require(len(rh)==4,"native R incomplete")
  matched=sum(a==b for a,b in zip(rh,recent))
  exact_native+=matched
  complete_native+=int(matched==4)
  pivot=[int(v) for v in rpivot.split(",")]
  exact_pivot+=int(pivot==src["pivot"])
 require(original_across_cpu==192 and complete_matlab==48,"genuine MATLAB cross-profile mismatch")
 require(input_transport==48 and exact_pivot==48,"native transport/pivots wrong")
 require(exact_native==123 and complete_native==5,"native Rust full R counts differ")
 require(verdict["exact_R_elements"]==exact_native and verdict["full_R_exact"]==complete_native,"authentic CI verdict differs")
 names=diag["candidate_names"];counts=diag["exact_case_counts"]
 require(len(names)==len(counts)==13,"QR operation candidates changed")
 for j,name in enumerate(names):
  require(sum(int(row["exact"][j]) for row in diag["records"])==counts[j],f"field tally {name}")
 require(dict(zip(names,counts))["householder_three_term"]==21,"numeric diagnostic moved")
 require(dict(zip(names,counts))["raw_norm"]==27,"norm diagnostic moved")
 return {"source_unseen":False, "exact_MATLAB_cross_AMD_R_entries":original_across_cpu,
         "original_robustfit_matches_public_qr_whole":complete_matlab,
         "native_transport_identical":input_transport,
         "native_pivots_exact":exact_pivot,
         "native_R_exact_entries":exact_native,
         "native_complete_R":complete_native,
         "qr_householder_best_three_term":dict(zip(names,counts))["householder_three_term"],
         "qr_norm_source_exact":dict(zip(names,counts))["raw_norm"],
         "artifacts_sha256_verified":len(SHA)}
if __name__=="__main__":
 try:print(json.dumps(check(),indent=2,sort_keys=True))
 except (AssertionError,ValueError,KeyError) as exc:
  print("FAIL_CLOSED",exc,file=sys.stderr)
  raise SystemExit(1) from exc
