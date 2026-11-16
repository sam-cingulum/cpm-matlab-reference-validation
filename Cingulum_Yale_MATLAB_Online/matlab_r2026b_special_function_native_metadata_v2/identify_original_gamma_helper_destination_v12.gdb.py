"""Sanitized library and public dynamic-symbol identity for observed gamma helper.

Executed only on a legitimately installed original MathWorks R2026b host.
No vendor disassembly, numeric output, register contents or proprietary
implementation is persisted. Whitelist only public standard libm symbols.
"""
import hashlib
import json
import os
import pathlib
import re
import gdb

EXPECTED_SHA="625bc659a790963d52dca039c66bcbde68c319caba37f89b85dd977c6a3be848"
PUBLIC_STANDARD_FUNCTIONS={"log", "log1p", "exp", "pow", "sqrt", "lgamma", "lgamma_r"}
gdb.execute("set pagination off",to_string=True)
gdb.execute("set confirm off",to_string=True)
gdb.execute("set debuginfod enabled off",to_string=True)
gdb.execute("set disable-randomization off",to_string=True)
gdb.execute("break before_helper_probe",to_string=True)
gdb.execute("run",to_string=True)
base=int(gdb.parse_and_eval("helper_probe_base"))
stub=int(gdb.parse_and_eval("helper_probe_stub"))
if stub-base!=0x632e0:
    raise RuntimeError("unexpected original shared gamma helper stub")
gdb.execute(f"tbreak *0x{stub:x}",to_string=True)
gdb.execute("continue",to_string=True)
if int(gdb.parse_and_eval("$pc"))!=stub:
    raise RuntimeError("original shared gamma helper not reached")
gdb.execute("stepi",to_string=True)
gdb.execute("stepi",to_string=True)
dest=int(gdb.parse_and_eval("$pc"))
if base <= dest < base + 0x400000:
    raise RuntimeError("expected externally resolved helper; original V11 evidence differs")

# GDB's `info symbol` identifies publicly linked libc/libm functions. We
# preserve only a specifically whitelisted symbol, not verbatim arbitrary
# vendor symbol labels or any vendor instruction/operand text.
sym=gdb.execute(f"info symbol 0x{dest:x}",to_string=True).strip()
match=re.match(r"^([A-Za-z_][A-Za-z_0-9]*)\s*(?:\+\s*\d+)?\s+in\s+section\s+",sym)
symbol=match.group(1) if match and match.group(1) in PUBLIC_STANDARD_FUNCTIONS else "unresolved_or_nonstandard"

# GDB mapping inspection returns only destination object filename; expose a
# library category, never an absolute path or proprietary object contents.
maps=gdb.execute("info proc mappings",to_string=True)
candidate="unresolved"
for line in maps.splitlines():
    cols=line.split()
    if len(cols)<5 or not cols[0].startswith("0x") or not cols[1].startswith("0x"):
        continue
    try:
        lo,hi=int(cols[0],16),int(cols[1],16)
    except ValueError:
        continue
    if lo<=dest<hi:
        name=pathlib.Path(cols[-1]).name
        if name.startswith("libm.so"):candidate="system_libm"
        elif name.startswith("libc.so"):candidate="system_libc"
        elif name.startswith("libmw"):candidate="other_mathworks_library"
        elif name.startswith("ld-linux"):candidate="dynamic_loader"
        else:candidate="other_or_anonymous"
        break

report={
    "classification":"ORIGINAL_R2026B_SHARED_GAMMA_HELPER_EXTERNAL_DESTINATION_IDENTITY_V12_SOURCE_DISCLOSED",
    "original_libmwmathspec_sha256":EXPECTED_SHA,
    "original_stub_relative_offset":"0x632e0",
    "destination_is_external_to_mathspec":True,
    "destination_library_category":candidate,
    "standard_public_symbol":symbol,
    "symbol_whitelist_only":True,
    "vendor_assembly_or_numeric_intermediates_exported":False,
    "independent_pure_rust_gamma_beta_parity":"NOT_CERTIFIED",
    "source_unseen_v12":"NOT_GENERATED",
}
out=pathlib.Path(os.environ["CINGULUM_HELPER_IDENTITY_V12_OUTPUT"])
out.write_text(json.dumps(report,sort_keys=True,indent=2)+"\n")
print("ORIGINAL_HELPER_STANDARD_SYMBOL",symbol,"CATEGORY",candidate)
print("RESULT_SHA256",hashlib.sha256(out.read_bytes()).hexdigest())
