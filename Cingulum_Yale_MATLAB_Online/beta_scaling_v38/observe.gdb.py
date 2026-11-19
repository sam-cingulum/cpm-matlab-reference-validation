"""Archive only categories of root-level log arguments, never raw observations."""
import csv
import gdb
import hashlib
import json
import math
import os
import re
import struct
from pathlib import Path

ROOT_OFFSET = 0xeb010
LOG_OFFSET = 0x632e0
execute = lambda command: gdb.execute(command, to_string=True)
integer = lambda expression: int(gdb.parse_and_eval(expression))

def run_to(address):
    execute(f"tbreak *{address:#x}")
    execute("continue")
    assert integer("$pc") == address

def argument():
    return float(gdb.parse_and_eval("$xmm0.v2_double[0]"))

def public_categories(a, b, x):
    y = 1.0 - x
    mean = a / (a + b)
    return {"x": x, "one_minus_x": y, "a": a, "b": b, "a_plus_b": a+b,
            "x_over_mean": x / mean, "y_over_other_mean": y / (b / (a + b))}

execute("set pagination off")
execute("set confirm off")
execute("set disable-randomization off")
execute("set debuginfod enabled off")
execute("break before_call")
execute("run")
data = Path("inputs.tsv").read_bytes()
commitment_bytes = os.environ["COMMITMENTS"].encode()
commitments = json.loads(commitment_bytes)
def agrees(key, value):
    # Compare against a prenominated independent prediction; never export
    # or hash an observed intermediate in a file or log.
    return hashlib.sha256(struct.pack(">d", value)).hexdigest() == commitments[row["id"][:-2]][key]

cases = list(csv.DictReader(data.decode().splitlines(), delimiter="\t"))
rows = []
for idx, row in enumerate(cases):
    assert integer("probe_index") == idx
    a, b, x = (struct.unpack(">d", bytes.fromhex(row[k+"_hex"]))[0] for k in "abx")
    assert argument() == x  # Known, independently authored ABI control.
    base = integer("probe_base")
    run_to(base + ROOT_OFFSET)
    ret = int.from_bytes(gdb.selected_inferior().read_memory(integer("$rsp"), 8).tobytes(), "little")
    predicates = public_categories(a, b, x)
    matches = []
    scales = []
    fractions = []
    predicates_met = {}
    for _ in range(1024):
        pc = integer("$pc")
        if pc == ret:
            break
        # V22 top-level tracing with all nested calls stepped over.
        asm = gdb.selected_frame().architecture().disassemble(pc, count=1)[0]["asm"]
        call = re.match(r"callq?\s+(0x[0-9a-fA-F]+)\b", asm.strip())
        if call and int(call.group(1), 16) == base + LOG_OFFSET:
            value = argument()
            matches.append(sorted(k for k, v in predicates.items() if value == v))
        target = int(call.group(1), 16) - base if call else None
        if target == 0x8cb20:
            predicates_met["log_scale"] = agrees("log_scale", argument())
        execute("nexti")
        if target == 0x8cb20:
            scales.append(argument())
        if target == 0xea900:
            fractions.append(argument())
    else:
        raise RuntimeError("root did not return within bound")
    # Early-return paths can omit a named operation. Score every missed
    # prediction as false and retain the number of observations on every row.
    lower = None
    if len(matches) == 3 and ("a" in matches[2]) != ("b" in matches[2]):
        lower = "a" in matches[2]
    upper_request = row["upper"] == "1"
    def deliver(direct):
        return 1.0-direct if upper_request == lower else direct
    have_scale = len(scales) == 1
    have_fraction = len(fractions) == 1
    compose = lower is not None and have_scale and have_fraction
    predicates_met.setdefault("log_scale", False)
    predicates_met.update(scale=have_scale and agrees("scale", scales[0]),
        fraction=have_fraction and agrees("fraction", fractions[0]),
        reciprocal_fraction=have_fraction and agrees("reciprocal_fraction", fractions[0]),
        root_equals_product=compose and argument() == deliver(scales[0] * fractions[0]),
        root_equals_quotient=compose and fractions[0] != 0 and argument() == deliver(scales[0] / fractions[0]),
        root_equals_forecast=agrees("upper" if upper_request else "lower", argument()))
    rows.append({"id":row["id"], "predicates":predicates_met, "lower_internal":lower,
                 "log_calls":len(matches),"scale_calls":len(scales),"fraction_calls":len(fractions)})
    if idx+1 < len(cases):
        execute("continue")
execute("continue")
assert integer("$_exitcode") == 0
Path("observed.json").write_text(json.dumps({
    "commit":os.environ["GITHUB_SHA"], "run":os.environ["GITHUB_RUN_ID"],
    "commitments_sha256":hashlib.sha256(commitment_bytes).hexdigest(),
    "input_sha256":hashlib.sha256(data).hexdigest(), "rows":rows,
    "classification":"developmental original stage agreement with preregistered binary64 commitments"
},sort_keys=True,indent=2)+"\n")
