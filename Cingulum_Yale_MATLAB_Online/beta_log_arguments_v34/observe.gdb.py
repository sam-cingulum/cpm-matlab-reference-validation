"""Archive only categories of root-level log arguments, never raw observations."""
import csv
import gdb
import hashlib
import json
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
        execute("nexti")
    else:
        raise RuntimeError("root did not return within bound")
    rows.append({"id":row["id"], "log_argument_labels":matches})
    if idx+1 < len(cases):
        execute("continue")
execute("continue")
assert integer("$_exitcode") == 0
Path("observed.json").write_text(json.dumps({
    "commit":os.environ["GITHUB_SHA"], "run":os.environ["GITHUB_RUN_ID"],
    "input_sha256":hashlib.sha256(data).hexdigest(), "rows":rows,
    "classification":"developmental public log argument predicate observations"
},sort_keys=True,indent=2)+"\n")
