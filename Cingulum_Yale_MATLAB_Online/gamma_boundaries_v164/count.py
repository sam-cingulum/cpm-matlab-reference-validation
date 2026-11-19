"""Observe only numerical function inputs/returns; original instructions stay local."""
import json
import struct
import gdb

gdb.execute("set pagination off")
gdb.execute("set confirm off")
gdb.execute("set disable-randomization off")
gdb.execute("set debuginfod enabled off")
rows = []
active = None
installed = False


def floating(index):
    return struct.pack(">d", float(gdb.parse_and_eval(f"$xmm{index}.v2_double[0]"))).hex()


class Returned(gdb.FinishBreakpoint):
    def __init__(self, row):
        super().__init__(gdb.newest_frame(), internal=True)
        self.row = row

    def stop(self):
        self.row["returned"] = floating(0)
        return False


class Entry(gdb.Breakpoint):
    def __init__(self, address, offset):
        super().__init__("*" + hex(address), internal=True)
        self.offset = offset

    def stop(self):
        if active is not None:
            assert len(active) < 20000
            row = dict(offset=self.offset, argument=floating(0), second=floating(1))
            active.append(row)
            Returned(row)
        return False


class Begin(gdb.Breakpoint):
    def stop(self):
        global active, installed
        if not installed:
            start = int(gdb.parse_and_eval("(uintptr_t)gamma_entry"))
            for offset in json.load(open("entries.json")):
                Entry(start + offset, offset)
            installed = True
        assert active is None
        active = []
        return False


class End(gdb.Breakpoint):
    def stop(self):
        global active
        assert active is not None
        assert all("returned" in row for row in active)
        rows.append(active)
        active = None
        return False


Begin("before_probe", internal=True)
End("after_probe", internal=True)
gdb.execute("run " + gdb.parameter("args") + " < probes.txt > traced.txt", to_string=True)
assert int(gdb.parse_and_eval("$_exitcode")) == 0
with open("counts.json", "w") as f:
    json.dump(rows, f)
