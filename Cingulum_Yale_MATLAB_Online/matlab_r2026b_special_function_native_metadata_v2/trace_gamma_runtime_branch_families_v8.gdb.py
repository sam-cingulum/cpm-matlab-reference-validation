"""GDB Python: original R2026b gamma branch-path metadata, NEVER instruction dumps.

Executed only on the SHA-verified original library and source-independent
public scalar inputs. Captured assembly stays in GDB memory. Output contains
aggregate instruction-family counts and hash of normalized visited addresses,
not original instructions, constants, XMM values or gamma numeric outputs.
"""
from __future__ import annotations
import collections
import hashlib
import json
import os
import pathlib
import re
import gdb

LABELS = [
    "0.125", "0.375", "0.5", "0.75", "0.99", "1",
    "1.01", "1.5", "2", "2.5", "3.5", "5",
    "10", "30", "100", "1000", "1/3", "5/3",
]
BASE = 0x8f1e0
EXPECTED_LIB_SHA = "625bc659a790963d52dca039c66bcbde68c319caba37f89b85dd977c6a3be848"

def value(symbol):
    return int(gdb.parse_and_eval(symbol))

def mnemonic():
    # Transient disassembly, never copied to the JSON or printed.
    line = gdb.execute("x/i $pc", to_string=True)
    match = re.search(r":\s*([a-zA-Z][\w.]*)\b", line)
    if not match:
        raise RuntimeError("unparsable live instruction")
    return match.group(1).lower(), line

def branch_destination(line):
    # Compute branch direction without publishing a vendor operand.
    target = re.search(r"\b0x([0-9a-fA-F]+)", line.split(":\t")[-1])
    if target is None:
        return None
    return int(target.group(1),16)

def category(mn):
    if re.fullmatch(r"v?(add|sub)sd",mn): return "f64_add_sub"
    if re.fullmatch(r"v?mulsd",mn): return "f64_mul"
    if re.fullmatch(r"v?divsd",mn): return "f64_div"
    if re.fullmatch(r"v?sqrtsd",mn): return "f64_sqrt"
    if any(x in mn for x in ("fmadd","fmsub","fnmadd","fnmsub")): return "f64_fma"
    if mn.startswith("call"): return "call_over"
    if mn.startswith("ret"): return "ret"
    if mn.startswith("j") and mn != "jmp": return "jcc"
    if mn.startswith("jmp"): return "jmp"
    return "other"

def trace(entry):
    pc = value("$pc")
    if pc != entry:
        raise RuntimeError("breakpoint did not stop at original hidden gamma entry")
    sp = value("$rsp")
    retaddr = int.from_bytes(gdb.selected_inferior().read_memory(sp,8).tobytes(),"little")
    counts = collections.Counter()
    path = hashlib.sha256()
    branches = collections.Counter()
    exit_to_caller = False
    for step in range(12000):
        pc = value("$pc")
        if pc == retaddr:
            exit_to_caller = True
            break
        mn,line = mnemonic()
        cat = category(mn)
        counts[cat] += 1
        if pc < entry or pc > entry+0x10000:
            # Leaving the region can happen for a tail call. Do not treat it
            # as a completed trace or pretend this captures subcall internals.
            raise RuntimeError("unexpected control-flow escape from gamma entry")
        path.update((pc-entry).to_bytes(4,"little",signed=False))
        target = branch_destination(line) if cat == "jcc" else None
        gdb.execute("nexti", to_string=True)
        nextpc = value("$pc")
        if cat == "jcc":
            if target is None:
                branches["undecodable"] += 1
            elif nextpc == target:
                branches["taken"] += 1
            else:
                branches["not_taken"] += 1
    if not exit_to_caller:
        raise RuntimeError("gamma tracer exceeded instruction limit")
    return {
        "executed_instructions_excluding_nested_call_bodies":sum(counts.values()),
        "scalar_instruction_categories":dict(sorted(counts.items())),
        "observed_jcc_directions":dict(sorted(branches.items())),
        "normalized_path_sha256":path.hexdigest(),
        "returned_to_original_abi_caller":True,
    }

def main():
    gdb.execute("set pagination off",to_string=True)
    gdb.execute("set confirm off",to_string=True)
    gdb.execute("set print static off",to_string=True)
    gdb.execute("set disable-randomization off",to_string=True)
    gdb.execute("set debuginfod enabled off",to_string=True)
    gdb.execute("break before_gamma_original_call",to_string=True)
    gdb.execute("run",to_string=True)
    runs = []
    hidden = value("gamma_probe_hidden_entry")
    if not hidden: raise RuntimeError("original hidden gamma pointer not initialized")
    for idx,label in enumerate(LABELS):
        if value("gamma_probe_case_index") != idx:
            raise RuntimeError("unexpected gamma case ordering at marker")
        if value("gamma_probe_hidden_entry") != hidden:
            raise RuntimeError("gamma function address changed")
        gdb.execute(f"tbreak *0x{hidden:x}",to_string=True)
        gdb.execute("continue",to_string=True)
        row = trace(hidden)
        row["index"] = idx
        row["source_independent_input_label"] = label
        runs.append(row)
        print("GAMMA_BRANCH_PROFILE", idx, label, row["executed_instructions_excluding_nested_call_bodies"], row["normalized_path_sha256"])
        if idx < len(LABELS)-1:
            gdb.execute("continue",to_string=True)
    gdb.execute("continue",to_string=True)
    uniques = collections.defaultdict(list)
    for x in runs: uniques[x["normalized_path_sha256"]].append(x["source_independent_input_label"])
    report = {
        "classification":"SHA_PINNED_ORIGINAL_MATHWORKS_R2026B_DYNAMIC_GAMMA_BRANCH_FAMILY_V8",
        "vendor_mathspec_sha256":EXPECTED_LIB_SHA,
        "sample_count":len(runs),
        "unique_runtime_path_count":len(uniques),
        "path_memberships":dict(sorted(uniques.items())),
        "cases":runs,
        "no_vendor_assembly_operands_constants_f64_intermediates_or_original_outputs_exported":True,
        "native_pure_Rust_gamma_or_beta_bit_parity":"NOT_CERTIFIED",
        "source_unseen_V12":"NOT_GENERATED",
        "scope_limit":"Executed top-level gamma instruction path, stepping over nested calls. One host CPU, 18 disclosed points. Not an algorithm derivation or exact Rust compatibility.",
    }
    out=pathlib.Path(os.environ["CINGULUM_TRACE_OUTPUT"])
    out.write_text(json.dumps(report,sort_keys=True,indent=2)+"\n")
    print("GAMMA_FAMILY_COUNT",len(uniques),"SHA256",hashlib.sha256(out.read_bytes()).hexdigest())

main()
