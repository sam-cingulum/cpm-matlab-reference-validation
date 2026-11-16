#!/usr/bin/env python3
"""Bounded *control-flow* architecture of the pinned original R2026b gamma/beta entry points.

Run only on a legitimately installed R2026b host. No vendor code, constants,
assembly, numeric outputs or register traces are persisted in the output. This
is structural metadata, NOT an independent gamma/beta implementation.
"""
from __future__ import annotations
import argparse
import collections
import hashlib
import json
import pathlib
import platform
import re
import subprocess

LIB_SHA = "625bc659a790963d52dca039c66bcbde68c319caba37f89b85dd977c6a3be848"
TARGETS = {"gammaln": 0x8f1e0, "betainc_normal": 0xeb010}
MAX_INSNS = 30000

def run(args: list[str]) -> str:
    p = subprocess.run(args, text=True, stdout=subprocess.PIPE,
                       stderr=subprocess.PIPE, timeout=150, check=False)
    if p.returncode:
        raise RuntimeError(f"command failed with exit {p.returncode}: {args[0]}: {p.stderr[:160]}")
    return p.stdout

def sha(path: pathlib.Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()

def instructions(lib: pathlib.Path, lo: int, hi: int):
    """Transient decoded assembly is intentionally never saved or published."""
    decoded = run(["objdump", "-d", "-M", "intel", "--no-show-raw-insn",
                   "--start-address", hex(lo), "--stop-address", hex(hi), str(lib)])
    rows = []
    for line in decoded.splitlines():
        m = re.match(r"^\s*([0-9a-fA-F]+):\s+([a-z][\w.]*)\s*(.*?)\s*$", line)
        if m:
            addr = int(m.group(1), 16)
            if lo <= addr < hi:
                rows.append((addr, m.group(2), m.group(3)))
    if not rows:
        raise AssertionError("empty disassembly")
    # Fallthrough is the address of the next decoded instruction, unless there is
    # a gap; the static disassembler may decode data as code in the *unreachable*
    # part, so traversal explicitly starts at the known original entrypoint.
    return {a: (mn, arg, rows[i+1][0] if i+1 < len(rows) else hi)
            for i, (a, mn, arg) in enumerate(rows)}

def direct_target(arg: str) -> int | None:
    m = re.match(r"^(?:0x)?([0-9a-fA-F]+)(?:\s|$)", arg)
    return int(m.group(1), 16) if m else None

def fp_category(mn: str) -> str | None:
    if re.fullmatch(r"v?(?:add|sub)sd", mn): return "scalar_f64_add_sub"
    if re.fullmatch(r"v?mulsd", mn): return "scalar_f64_mul"
    if re.fullmatch(r"v?divsd", mn): return "scalar_f64_div"
    if re.fullmatch(r"v?sqrtsd", mn): return "scalar_f64_sqrt"
    if "fmadd" in mn or "fmsub" in mn: return "fused_multiply_add"
    return None

def audit_cfg(lib: pathlib.Path, name: str, entry: int, end: int):
    program = instructions(lib, entry, end)
    todo = [entry]
    seen = set()
    counts = collections.Counter()
    call_targets = collections.Counter()
    exit_targets = collections.Counter()
    ret = []
    unresolved = []
    nonlocal_jumps = []
    while todo:
        at = todo.pop()
        if at in seen:
            continue
        if len(seen) >= MAX_INSNS:
            raise RuntimeError(f"{name}: safety cap {MAX_INSNS} instructions")
        if at not in program:
            unresolved.append(at)
            continue
        seen.add(at)
        mn, arg, following = program[at]
        if fp := fp_category(mn): counts[fp] += 1
        if mn.startswith("ret"):
            counts["ret_sites"] += 1
            ret.append(at)
            continue
        if mn.startswith("call"):
            counts["call_sites"] += 1
            target = direct_target(arg)
            call_targets[hex(target) if target is not None else "indirect"] += 1
            todo.append(following)
            continue
        if mn.startswith("jmp"):
            counts["unconditional_jumps"] += 1
            target = direct_target(arg)
            if target is None:
                exit_targets["indirect_jump"] += 1
            elif entry <= target < end:
                todo.append(target)
            else:
                nonlocal_jumps.append(target)
                exit_targets["direct_outside_window"] += 1
            continue
        if mn.startswith("j") and mn != "jmp":
            counts["conditional_branches"] += 1
            target = direct_target(arg)
            todo.append(following)
            if target is None:
                unresolved.append(at)
            elif entry <= target < end:
                todo.append(target)
            else:
                nonlocal_jumps.append(target)
                exit_targets["conditional_target_outside_window"] += 1
            continue
        todo.append(following)

    assert entry in seen
    # Address metadata only: an observed return is not necessarily a complete
    # function-boundary certification when indirect jumps or outside edges exist.
    return {
        "entry": hex(entry),
        "window_end": hex(end),
        "name": name,
        "reachable_instructions_static": len(seen),
        "reachable_instruction_address_max": hex(max(seen)),
        "reachable_return_offsets": [hex(x-entry) for x in sorted(ret)],
        "reachability_counts": dict(sorted(counts.items())),
        "direct_call_target_site_counts": dict(sorted(call_targets.items())),
        "escape_counts": dict(sorted(exit_targets.items())),
        "outside_window_jump_target_offsets": [hex(x-entry) for x in sorted(set(nonlocal_jumps))],
        "unresolved_static_target_count": len(unresolved),
        "closed_function_boundary_proven":
            not unresolved and not nonlocal_jumps and not exit_targets.get("indirect_jump", 0),
    }

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("matlab_root")
    ap.add_argument("output_json")
    args = ap.parse_args()
    root = pathlib.Path(args.matlab_root)
    lib = root / "bin/glnxa64/libmwmathspec.so"
    if sha(lib) != LIB_SHA:
        raise RuntimeError("FAIL CLOSED: unexpected original vendor library SHA")
    if platform.machine() != "x86_64":
        raise RuntimeError("requires R2026b Linux x86_64")
    # Exact wrapper-derived entry locations are already source-authenticated in
    # the V4/V6 structural evidence; this test does not dynamically resolve them.
    results = {
        "gammaln": audit_cfg(lib, "gammaln", TARGETS["gammaln"], 0x93000),
        "betainc_normal": audit_cfg(lib, "betainc_normal", TARGETS["betainc_normal"], 0xf1000)
    }
    report = {
        "classification": "R2026B_ORIGINAL_SHA_PINNED_STATIC_ENTRY_CFG_V7_ONLY",
        "original_library_sha256": LIB_SHA,
        "original_matlab_release": "R2026b",
        "host_machine": platform.machine(),
        "vendor_code_assembly_constants_numeric_outputs_exported": False,
        "compiled_pure_Rust_gamma_beta_exactness": "NOT_CERTIFIED",
        "source_unseen_V12": "NOT_GENERATED",
        "scope_limit": "Static direct-control-flow approximation; calls not inlined, indirect branches unresolved, path feasibility not inferred; no claim of actual dynamic branch selection",
        "entry_reachability": results,
    }
    out = pathlib.Path(args.output_json)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(report, sort_keys=True, indent=2) + "\n")
    for name, value in results.items():
        print(name, "reachable", value["reachable_instructions_static"],
              "returns", len(value["reachable_return_offsets"]),
              "outside", value["escape_counts"],
              "fp", {k:v for k,v in value["reachability_counts"].items() if "f64" in k})
    print("STRUCTURAL_METADATA_SHA256", sha(out))
    print("PURE_RUST_SPECIAL_FUNCTION_EXACTNESS_NOT_CERTIFIED")

if __name__ == "__main__":
    main()
