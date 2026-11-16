"""Authorized R2026b indirect helper runtime destination; sanitized metadata only."""
import json,os,pathlib,re,hashlib
import gdb

gdb.execute("set pagination off",to_string=True)
gdb.execute("set confirm off",to_string=True)
gdb.execute("set debuginfod enabled off",to_string=True)
gdb.execute("set disable-randomization off",to_string=True)
gdb.execute("break before_helper_probe",to_string=True)
gdb.execute("run",to_string=True)
base=int(gdb.parse_and_eval("helper_probe_base"))
stub=int(gdb.parse_and_eval("helper_probe_stub"))
if stub-base!=0x632e0:raise RuntimeError("unexpected helper stub")
gdb.execute("tbreak *0x%x"%stub,to_string=True)
gdb.execute("continue",to_string=True)
if int(gdb.parse_and_eval("$pc"))!=stub:raise RuntimeError("helper was not called")
# The static V10 test proved the trampoline is only two instructions,
# and one is an indirect jump. Execute both without disclosing assembly.
gdb.execute("stepi",to_string=True)
first=int(gdb.parse_and_eval("$pc"))
gdb.execute("stepi",to_string=True)
dest=int(gdb.parse_and_eval("$pc"))
def locus(a):
    data=gdb.execute("info symbol 0x%x"%a,to_string=True).strip()
    # GDB may return proprietary symbol strings: never emit them verbatim.
    return "anonymous_or_dynamic"
report={
    "classification":"SHA_PINNED_ORIGINAL_R2026B_RUNTIME_INDIRECT_GAMMA_HELPER_DESTINATION_V11",
    "original_libmwmathspec_sha256":"625bc659a790963d52dca039c66bcbde68c319caba37f89b85dd977c6a3be848",
    "known_indirect_stub_offset":"0x632e0",
    "first_step_relative_offset":hex(first-base) if first>=base else "outside_original_lib",
    "resolved_second_step_relative_offset":hex(dest-base) if dest>=base else "outside_original_lib",
    "resolved_destination_within_original_vendor_library":base<=dest<base+0x400000,
    "symbol_resolution_locus":locus(dest),
    "original_numeric_outputs_provided":False,
    "vendor_instruction_or_operand_bytes_provided":False,
    "not_complete_original_algorithm":True,
    "pure_Rust_gamma_beta_exactness":"NOT_CERTIFIED",
    "source_unseen_V12":"NOT_GENERATED",
}
out=pathlib.Path(os.environ["CINGULUM_HELPER_V11_OUTPUT"])
out.write_text(json.dumps(report,sort_keys=True,indent=2)+"\n")
print("SANITIZED_RESOLVED_HELPER_BRANCH_RESEARCH_ONLY")
