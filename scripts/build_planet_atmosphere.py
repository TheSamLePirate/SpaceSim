"""Finite, double-sided atmosphere shell (110 km radius): the sky seen from the ground,
the horizon band and the orbital halo are all drawn from this one mesh by main-f.sdr."""
from build_planet import DATA,FACES,pof,mesh
vs=[];fs=[];uv=[]
for face in FACES:
    for inward in [False,True]:
        vv,ff,tt=mesh(face,72,shell=-30000,inward=inward);off=len(vs);vs+=vv;fs+=[tuple(i+off for i in f) for f in ff];uv+=tt
assert len(vs)<65536
pof(DATA/'models/ss_atmo_0.pof',[(vs,fs,uv)],['ss_air-trans'])
print('Atmosphere shell: 110 km radius, double-sided,',len(fs),'triangles')
