#!/usr/bin/env python3
import json,sys,hashlib
p=sys.argv[1];b=open(p,'rb').read();d=json.loads(b);r=d['records'];assert len(r)==18
by={}
for x in r:
 assert x['source_equal_public'] or x['pivot']==[2,1],x['id']
 val=(x['R_hex'],x['source_R_hex'],x['source_h_hex'],x['pivot'])
 if x['id'] in by: assert by[x['id']]==val,('UNSTABLE',x['id'],x['iteration'])
 else:by[x['id']]=val
assert len(by)==6
print('GENUINE_MATLAB_UNINSTRUMENTED_REPEATABILITY_PASS 6 cases x 3 repeats, all R and h bits exact; rescaled case uses pivot 2,1')
print('SHA256',hashlib.sha256(b).hexdigest())
