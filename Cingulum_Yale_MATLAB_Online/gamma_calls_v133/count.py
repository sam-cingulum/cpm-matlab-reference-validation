"""Count calls to public system libm functions. Export only names and counts."""
import collections
import json
import gdb

gdb.execute("set pagination off")
gdb.execute("set confirm off")
gdb.execute("set disable-randomization off")
gdb.execute("set debuginfod enabled off")
rows = []
active = None
installed = False


class SystemEntry(gdb.Breakpoint):
    def __init__(self, addr, names):
        super().__init__("*" + hex(addr), internal=True)
        self.label = "/".join(sorted(set(names)))

    def stop(self):
        if active is not None:
            active[self.label] += 1
        return False


class Begin(gdb.Breakpoint):
    def stop(self):
        global active, installed
        if not installed:
            addresses = collections.defaultdict(list)
            for i in range(int(gdb.parse_and_eval("sizeof(names)/sizeof(names[0])"))):
                name = gdb.parse_and_eval(f"names[{i}]").string()
                for j in (0, 1):
                    addr = int(gdb.parse_and_eval(f"system_math[{i}][{j}]"))
                    if addr:
                        addresses[addr].append(name)
            for addr, names in addresses.items():
                SystemEntry(addr, names)
            installed = True
        assert active is None
        active = collections.Counter()
        return False


class End(gdb.Breakpoint):
    def stop(self):
        global active
        assert active is not None
        rows.append(dict(active))
        active = None
        return False


Begin("before_probe", internal=True)
End("after_probe", internal=True)
gdb.execute("run " + gdb.parameter("args") + " < probes.txt > traced.txt", to_string=True)
assert int(gdb.parse_and_eval("$_exitcode")) == 0
with open("counts.json", "w") as f:
    json.dump(rows, f)
