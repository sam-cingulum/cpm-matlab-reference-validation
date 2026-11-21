"""Record numerical register states at backward branches of the original gamma entry."""
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


class LoopState(gdb.Breakpoint):
    def __init__(self, address, offset):
        super().__init__("*" + hex(address), internal=True)
        self.offset = offset

    def stop(self):
        if active is not None:
            assert len(active) < 20000
            values = [struct.pack(">d", float(gdb.parse_and_eval(
                f"$xmm{i}.v2_double[0]"))).hex() for i in range(16)]
            integers = {r: str(int(gdb.parse_and_eval("$" + r)))
                        for r in ("rax", "rbx", "rcx", "rdx", "r8", "r9", "r10", "r11", "r12", "r13", "r14", "r15")}
            active.append(dict(offset=self.offset, floating=values, integers=integers))
        return False


class Begin(gdb.Breakpoint):
    def stop(self):
        global active, installed
        if not installed:
            start = int(gdb.parse_and_eval("(uintptr_t)gamma_entry"))
            for offset in json.load(open("branches.json")):
                LoopState(start + offset, offset)
            installed = True
        assert active is None
        active = []
        return False


class End(gdb.Breakpoint):
    def stop(self):
        global active
        assert active is not None
        rows.append(active)
        active = None
        return False


Begin("before_probe", internal=True)
End("after_probe", internal=True)
gdb.execute("run " + gdb.parameter("args") + " < probes.txt > traced.txt", to_string=True)
assert int(gdb.parse_and_eval("$_exitcode")) == 0
with open("counts.json", "w") as f:
    json.dump(rows, f)
