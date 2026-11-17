"""Sanitized genuine R2026b beta call-target classification, no vendor source.

Original installed binary is separately SHA pinned by the workflow. We only
export public standard math symbol names and provider categories, plus counts
for possible native internal call destinations. Neither operand values nor
original instructions, arguments, bytes, numerics or branch data are copied.
"""
from __future__ import annotations
import hashlib
import json
import os
import pathlib
import re
import gdb

EXPECTED_SHA="625bc659a790963d52dca039c66bcbde68c319caba37f89b85dd977c6a3be848"
CALL_TARGETS=[0x629a0,0x62a20,0x62a40,0x632d0,0x632e0,0x68ee0,0x8cb20,0x8f1e0,0x9d750,0xea900]
PUBLIC_SYSTEM_FUNCTIONS={
    "exp", "exp2", "expm1", "log", "log1p", "log2", "log10",
    "pow", "sqrt", "lgamma", "lgamma_r", "tgamma", "sin", "cos",
    "floor", "ceil", "erf", "erfc", "atan", "frexp", "fma",
}

gdb.execute("set pagination off",to_string=True)
gdb.execute("set confirm off",to_string=True)
gdb.execute("set disable-randomization off",to_string=True)
gdb.execute("set debuginfod enabled off",to_string=True)
gdb.execute("break before_helper_probe",to_string=True)
gdb.execute("run",to_string=True)
base=int(gdb.parse_and_eval("helper_probe_base"))
assert int(gdb.parse_and_eval("helper_probe_stub"))-base==0x632e0

mapping_lines=gdb.execute("info proc mappings",to_string=True).splitlines()
def category(dest):
    for line in mapping_lines:
        cols=line.split()
        if len(cols)<5 or not cols[0].startswith("0x") or not cols[1].startswith("0x"):
            continue
        try:lo,hi=int(cols[0],16),int(cols[1],16)
        except ValueError:continue
        if lo<=dest<hi:
            name=pathlib.Path(cols[-1]).name
            if name.startswith("libm.so"):return "system_libm"
            if name.startswith("libc.so"):return "system_libc"
            if name.startswith("libmw"):return "other_mathworks_library"
            if name.startswith("ld-linux"):return "dynamic_loader"
            return "other_or_anonymous"
    return "unmapped"

def public_symbol(dest):
    text=gdb.execute(f"info symbol 0x{dest:x}",to_string=True).strip()
    match=re.match(r"^([A-Za-z_][A-Za-z_0-9]*)\s*(?:\+\s*\d+)?\s+in\s+section\s+",text)
    return match.group(1) if match and match.group(1) in PUBLIC_SYSTEM_FUNCTIONS else "unresolved_or_nonstandard"

def instruction_type():
    # Returned GDB disassembly is private in memory, NEVER in any artifact.
    raw=gdb.execute("x/i $pc",to_string=True).lower()
    tail=raw.split(":",1)[-1]
    mn=re.search(r"^\s*([a-z][a-z0-9_.]*)\b",tail)
    if mn is None:return "other"
    m=mn.group(1)
    if m.startswith("jmp"):return "jmp"
    if m.startswith("mov"):return "safe_mov"
    if m.startswith("lea"):return "safe_lea"
    if m in ("nop","endbr64"):return m
    return "internal_computational_instruction"

result=[]
for at in CALL_TARGETS:
    start=base+at
    gdb.execute(f"set $pc = 0x{start:x}",to_string=True)
    first=instruction_type()
    steps=0
    dest=start
    if first in ("jmp","safe_mov","safe_lea","nop","endbr64"):
        # Execution is bounded to at most two instructions and can only pass
        # through benign register/GOT loads and a single forwarding jump.
        gdb.execute("stepi",to_string=True)
        steps=1
        dest=int(gdb.parse_and_eval("$pc"))
        second=instruction_type() if base<=dest<base+0x400000 else "external"
        if first=="jmp" and second=="jmp":
            gdb.execute("stepi",to_string=True)
            steps+=1
            dest=int(gdb.parse_and_eval("$pc"))
        elif first in ("safe_mov","safe_lea","nop","endbr64") and second=="jmp":
            gdb.execute("stepi",to_string=True)
            steps+=1
            dest=int(gdb.parse_and_eval("$pc"))
    else:
        second="not_stepped"
    is_external=not(base<=dest<base+0x400000)
    result.append({
        "original_direct_call_target_offset":hex(at),
        "first_instruction_category":first,
        "second_instruction_category":second,
        "forwarding_steps_executed":steps,
        "destination_external_to_mathspec":is_external,
        "destination_library_category":category(dest) if is_external else "original_mathspec_internal",
        "public_standard_symbol":public_symbol(dest) if is_external else "not_public_standard_symbol",
        "numerical_function_body_executed":False,
    })

report={
    "classification":"SHA_PINNED_ORIGINAL_MATHWORKS_R2026B_BETA_CALL_TARGET_PUBLIC_STANDARD_CLASSIFICATION_V18",
    "original_libmwmathspec_sha256":EXPECTED_SHA,
    "target_count":len(CALL_TARGETS),
    "previous_v17_first_instruction_classifier":"INSUFFICIENT_MISLABELLED_SAFE_MOV_LOADS_AS_OTHER",
    "beta_hidden_original_entry_offset":"0xeb010",
    "sanitized_call_target_classification":result,
    "vendor_instructions_bytes_constants_register_contents_or_original_outputs_distributed":False,
    "independent_pure_Rust_betainc_lower_upper_bit_parity":"NOT_CERTIFIED",
    "source_unseen_V12":"NOT_GENERATED",
    "scope_limit":"One originally installed host; structural call destinations do not establish argument mappings or beta recurrence numerical order",
}
out=pathlib.Path(os.environ["CINGULUM_BETA_CALL_TARGET_OUTPUT"])
out.write_text(json.dumps(report,sort_keys=True,indent=2)+"\n")
print("BETA_PUBLIC_STANDARD_NUMERICAL_HELPER_CLASSIFICATION_ONLY")
print("OUTPUT_SHA256",hashlib.sha256(out.read_bytes()).hexdigest())
