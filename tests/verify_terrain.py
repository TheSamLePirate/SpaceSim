"""Check generated geometry and the real FSO flight/physics evidence."""
from pathlib import Path
import collections
import math
import re
import struct
import sys
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'scripts'))
from build_terrain import terrain_mesh,face_normal,height,GRID

root=Path(__file__).resolve().parents[1]
vertices,faces=terrain_mesh(GRID)
edges=collections.Counter()
directions=collections.Counter()
for face in faces:
    assert len(set(face))==3
    face_normal(*(vertices[i] for i in face))
    for a,b in zip(face,face[1:]+face[:1]):
        edges[tuple(sorted((a,b)))]+=1
        directions[(a,b)]+=1
assert all(count==2 for count in edges.values()),'Mesh is not closed'
assert all(directions[(a,b)]==directions[(b,a)] for a,b in edges),'Inconsistent face winding'
blob=(root/'mods/terrain/data/models/ss_terrain.pof').read_bytes()
assert blob[:4]==b'PSPO'
assert struct.unpack_from('<i',blob,4)[0]==2117
pos=8;tags=[]
while pos<len(blob):
    tag=blob[pos:pos+4];size=struct.unpack_from('<I',blob,pos+4)[0]
    assert pos+8+size<=len(blob)
    tags.append(tag);pos+=8+size
assert pos==len(blob) and tags.count(b'OBJ2')==2 and b'TXTR' in tags
log=(root/'artifacts/terrain/validation-m1max.txt').read_text()
assert log.count(' START ')==1,'Test must use a single mission entry'
assert 'RESULT status=PASS' in log
assert 'ALTITUDE_GOAL reached=true same_mission=true' in log
assert 'mission=_SPT_Terrain_Auto' in log
rays=re.findall(r'RAY_HIT x=([-\d.]+) y=([-\d.]+) z=([-\d.]+)',log)
assert len(rays)==5
for x,y,z in rays:
    assert abs(float(y)-height(float(x),float(z)))<10,'Engine ray hit does not match generated terrain'
incoming=float(re.search(r'incoming_vy=([-\d.]+)',log)[1])
response=float(re.search(r'NATIVE_RESPONSE .* vy=([-\d.]+)',log)[1])
assert incoming==-25 and response>incoming+5,'Native physics must alter the incoming velocity'
clearance=float(re.search(r'PROBE_FINAL clearance=([-\d.]+)',log)[1])
assert clearance>0,'Probe must remain above the mesh after impact'
flights=re.findall(r'FLIGHT x=([-\d.]+) y=([-\d.]+) z=([-\d.]+) agl=([-\d.]+)',log)
assert float(flights[0][3])<250
assert any(float(f[1])>=5500 for f in flights)
assert float(re.search(r'max_step_m=([-\d.]+)',log)[1])<100,'No large jump in the continuous trajectory'
assert '.Position=' not in (root/'mods/terrain/data/tables/spacesim-terrain-sct.lua').read_text(),'Flight test must not teleport the player'
print(f'PASS: closed terrain ({len(vertices)} vertices, {len(faces)} triangles), POF chunks, 5 engine ray hits, native collision response, final clearance {clearance:.3f} m, continuous ascent beyond 5.5 km.')
