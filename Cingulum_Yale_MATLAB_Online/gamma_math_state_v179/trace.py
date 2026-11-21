"""Original-only IEEE binary64 register snapshots at arithmetic sites.

Arithmetic-site selection is generated locally on the licensed original
runner from ephemeral disassembly. No proprietary instructions or bytes are
included in public artifacts, Rust code, or analysis reports.
"""
import json
import struct
import gdb

gdb.execute("set pagination off")
gdb.execute("set confirm off")
gdb.execute("set disable-randomization off")
gdb.execute("set debuginfod enabled off")
rows=[]
active=None
installed=False
num_sites=0

class MathSite(gdb.Breakpoint):
    def __init__(self, at, relative):
        super().__init__("*"+hex(at), internal=True)
        self.relative=relative

    def stop(self):
        if active is not None:
            assert len(active)<10000
            values=[struct.pack(">d",float(gdb.parse_and_eval(
                f"$xmm{k}.v2_double[0]"))).hex() for k in range(8)]
            active.append({"offset":self.relative,"floating":values})
        return False

class Begin(gdb.Breakpoint):
    def stop(self):
        global active,installed,num_sites
        if not installed:
            start=int(gdb.parse_and_eval("(uintptr_t)gamma_entry"))
            sites=json.load(open("math_sites.json"))
            assert 50<len(sites)<2500
            for site in sites:
                MathSite(start+site,site)
            num_sites=len(sites)
            installed=True
        assert active is None
        active=[]
        return False

class End(gdb.Breakpoint):
    def stop(self):
        global active
        assert active is not None
        rows.append(active)
        active=None
        return False

Begin("before_probe",internal=True)
End("after_probe",internal=True)
gdb.execute("run " + gdb.parameter("args") +
            " < probes.txt > traced.txt",to_string=True)
assert int(gdb.parse_and_eval("$_exitcode"))==0
with open("math_counts.json","w") as output:
    json.dump({"site_count":num_sites,"rows":rows},output)
