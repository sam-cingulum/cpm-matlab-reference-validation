"""Genuine R2026b beta nested-helper dynamic branch path, never vendor assembly or numerics.

Original C++ caller and GDB script are independently user-authored. Program
steps over all deeper MathWorks and libm calls, only exporting category counts,
SHA256 of original root instruction-address paths and bounded call site counts.
No proprietary code, values, operands, numerical answers or intermediates
are transferred to Rust or saved in the artifact.
"""
from __future__ import annotations
import collections,hashlib,json,os,pathlib,re
import gdb

LABELS=["halves_low_lower", "halves_low_upper", "halves_mid_lower", "halves_mid_upper", "halves_high_lower", "halves_high_upper", "small_low_lower", "small_low_upper", "small_mid_lower", "small_mid_upper", "small_high_lower", "small_high_upper", "mid_low_lower", "mid_low_upper", "mid_mid_lower", "mid_mid_upper", "mid_high_lower", "mid_high_upper", "large_low_lower", "large_low_upper", "large_mid_lower", "large_mid_upper", "large_high_lower", "large_high_upper"]
ENTRY_OFFSET=0xeb010
EXPECTED_SHA="625bc659a790963d52dca039c66bcbde68c319caba37f89b85dd977c6a3be848"
CALL_TARGETS={
  0x629a0,0x62a20,0x62a40,0x632d0,0x632e0,
  0x68ee0,0x8cb20,0x8f1e0,0x9d750,0xea900,
}
def value(e):return int(gdb.parse_and_eval(e))
def mnemonic():
    # Original instructions inspected transiently inside GDB, never exported.
    line=gdb.execute("x/i $pc",to_string=True)
    match=re.search(r":\s*([a-zA-Z][\w.]*)\b",line)
    if match is None:raise RuntimeError("unparsable vendor instruction metadata")
    return match.group(1).lower(),line
def category(mn):
    if re.fullmatch(r"v?(add|sub)sd",mn):return "f64_add_sub"
    if re.fullmatch(r"v?mulsd",mn):return "f64_mul"
    if re.fullmatch(r"v?divsd",mn):return "f64_div"
    if re.fullmatch(r"v?sqrtsd",mn):return "f64_sqrt"
    if any(x in mn for x in ("fmadd","fmsub","fnmadd","fnmsub")):return "f64_fma"
    if mn.startswith("call"):return "nested_call_stepped_over"
    if mn.startswith("ret"):return "return"
    if mn.startswith("j") and mn not in ("jmp","jmpq"):return "conditional_branch"
    if mn.startswith("jmp"):return "unconditional_jump"
    return "other"
def direct_target(raw):
    # Structural offsets, never vendor operands/source; public structural
    # whitelist derived in a previous independently SHA-pinned genuine run.
    x=re.search(r"\b0x([0-9a-fA-F]+)",raw.split(":\t")[-1])
    return int(x.group(1),16) if x else None
def trace(entry,base):
    if value("$pc")!=entry:raise RuntimeError("wrong hidden beta numerical entry")
    sp=value("$rsp")
    retaddr=int.from_bytes(gdb.selected_inferior().read_memory(sp,8).tobytes(),"little")
    counts=collections.Counter()
    paths=hashlib.sha256()
    branches=collections.Counter()
    calls=collections.Counter()
    exits=collections.Counter()
    for step in range(25000):
        pc=value("$pc")
        if pc==retaddr:
            exits["original_caller"]+=1
            break
        if not base <= pc < base+0x250000:
            raise RuntimeError("original beta numeric body unexpectedly left original MathWorks binary")
        mn,raw=mnemonic()
        cat=category(mn)
        counts[cat]+=1
        paths.update((pc-base).to_bytes(4,"little",signed=False))
        target=direct_target(raw) if cat in ("nested_call_stepped_over","conditional_branch") else None
        if cat=="nested_call_stepped_over" and target is not None:
            relative=target-base
            calls[hex(relative) if relative in CALL_TARGETS else "other_original_or_external_calls"]+=1
        # Step OVER nested numerical functions. Their arithmetic is not
        # accessed; the trace covers only the beta root/top-level path.
        gdb.execute("nexti",to_string=True)
        nextpc=value("$pc")
        if cat=="conditional_branch":
            if target is None:branches["target_unresolved"]+=1
            elif nextpc==target:branches["taken"]+=1
            else:branches["not_taken"]+=1
    else:
        raise RuntimeError("bounded original beta root path did not return")
    return {
        "helper_top_level_executed_instruction_count":sum(counts.values()),
        "scalar_and_control_instruction_category_counts":dict(sorted(counts.items())),
        "conditional_branch_directions":dict(sorted(branches.items())),
        "helper_direct_call_sites":dict(sorted(calls.items())),
        "helper_path_normalized_sha256":paths.hexdigest(),
        "returned_to_original_abi_caller":exits["original_caller"]==1,
    }


SELECTED=set(range(24))
HELPERS={0xea900:"h2_beta_associated"}
gdb.execute("set pagination off",to_string=True)
gdb.execute("set confirm off",to_string=True)
gdb.execute("set print static off",to_string=True)
gdb.execute("set disable-randomization off",to_string=True)
gdb.execute("set debuginfod enabled off",to_string=True)
gdb.execute("break before_beta_original_call",to_string=True)
gdb.execute("run",to_string=True)
root=value("beta_probe_hidden_entry")
base=root-ENTRY_OFFSET
if root<=base or base==0:raise RuntimeError("unexpected original beta base")
rows=[]
for idx,label in enumerate(LABELS):
    if value("beta_probe_case_index")!=idx:
        raise RuntimeError("original beta parameter case drift")
    if idx in SELECTED:
        for offset in HELPERS:
            gdb.execute(f"tbreak *0x{base+offset:x}",to_string=True)
        observed=set()
        for _ in range(len(HELPERS)):
            gdb.execute("continue",to_string=True)
            offset=value("$pc")-base
            if offset not in HELPERS or offset in observed:
                raise RuntimeError("expected one original entry of each hidden shared numerical helper")
            observed.add(offset)
            result=trace(base+offset,base)
            result["index"]=idx
            result["source_disclosed_input_label"]=label
            result["original_internal_helper_offset"]=hex(offset)
            result["original_internal_helper_id"]=HELPERS[offset]
            rows.append(result)
            print("SANITIZED_NESTED_HELPER_PATH",idx,label,hex(offset),result["helper_top_level_executed_instruction_count"],result["helper_path_normalized_sha256"])
        assert observed==set(HELPERS)
    if idx+1<len(LABELS):
        gdb.execute("continue",to_string=True)
gdb.execute("continue",to_string=True)
paths=collections.defaultdict(lambda:collections.defaultdict(list))
for r in rows:
    paths[r["original_internal_helper_id"]][r["helper_path_normalized_sha256"]].append(r["source_disclosed_input_label"])
report={
    "classification":"GENUINE_SHA_PINNED_ORIGINAL_R2026B_HIDDEN_BETAINC_NESTED_HELPER_DYNAMIC_PATHS_V24",
    "original_mathspec_sha256":EXPECTED_SHA,
    "original_beta_root_entry_offset":"0xeb010",
    "original_helper_entry_offsets":[hex(x) for x in HELPERS],
    "source_disclosed_input_count":len(SELECTED),
    "actual_helper_executions":len(rows),
    "unique_execution_paths_by_helper":{k:len(p) for k,p in paths.items()},
    "path_memberships_by_helper":{k:dict(sorted(p.items())) for k,p in paths.items()},
    "helper_execution_summaries":rows,
    "numeric_calls_stepped_over":True,
    "original_vendor_assembly_operands_constants_registers_values_or_output_distributed":False,
    "original_numeric_algorithm_identified":"NOT_YET",
    "pure_Rust_betainc_lower_upper_all_grid_exact":"NOT_CERTIFIED",
    "source_unseen_V12":"NOT_GENERATED",
    "limitation":"One original hidden helper 0xea900 on 24 preregistered shape-vs-x points, stepping over nested calls. Path identity does not prove argument independence or numerical identity.",
}
out=pathlib.Path(os.environ["CINGULUM_BETA_NESTED_V24_OUTPUT"])
out.write_text(json.dumps(report,sort_keys=True,indent=2)+"\n")
print("BETA_NESTED_ORIGINAL_PATHS",len(rows),"SHA256",hashlib.sha256(out.read_bytes()).hexdigest())
