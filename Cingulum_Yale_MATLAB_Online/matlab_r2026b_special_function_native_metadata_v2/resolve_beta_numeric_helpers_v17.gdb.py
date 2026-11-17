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
    mn=re.search(r"\b(jmp|jmpq|endbr64|nop|pushq?|callq?|retq?)\b",tail)
    return mn.group(1) if mn else "arithmetic_or_other"

result=[]
for at in CALL_TARGETS:
    start=base+at
    gdb.execute(f"set $pc = 0x{start:x}",to_string=True)
    first=instruction_type()
    steps=0
    dest=start
    if first.startswith("jmp"):
        # Stepping a GOT/PLT forwarding jump only; avoid numerical function
        # bodies altogether. Bound the trace to 2 forwarding instructions.
        for _ in range(2):
            gdb.execute("stepi",to_string=True)
            dest=int(gdb.parse_and_eval("$pc"))
            steps+=1
            if not(base<=dest<base+0x400000):break
            if not instruction_type().startswith("jmp"):break
    elif first=="endbr64":
        gdb.execute("stepi",to_string=True)
        steps=1
        if instruction_type().startswith("jmp"):
            gdb.execute("stepi",to_string=True)
            steps+=1
            dest=int(gdb.parse_and_eval("$pc"))
    is_external=not(base<=dest<base+0x400000)
    result.append({
        "original_direct_call_target_offset":hex(at),
        "first_instruction_category":first,
        "forwarding_steps_executed":steps,
        "destination_external_to_mathspec":is_external,
        "destination_library_category":category(dest) if is_external else "original_mathspec_internal",
        "public_standard_symbol":public_symbol(dest) if is_external else "not_public_standard_symbol",
        "numerical_function_body_executed":False,
    })

report={
    "classification":"SHA_PINNED_ORIGINAL_MATHWORKS_R2026B_BETA_CALL_TARGET_PUBLIC_STANDARD_CLASSIFICATION_V17",
    "original_libmwmathspec_sha256":EXPECTED_SHA,
    "target_count":len(CALL_TARGETS),
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
