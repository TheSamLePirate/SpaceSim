"""Validate the shipped globe topology, real POF triangles, materials and flight evidence."""
from pathlib import Path
from collections import Counter
import json,math,re,struct,sys
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
DATA=ROOT/'mods/planet/data'
unpack=lambda fmt,b,o=0:struct.unpack_from('<'+fmt,b,o)
edges=Counter();directions=Counter();triangles=0
for path in sorted((DATA/'models').glob('ss_p_*.pof')):
 blob=path.read_bytes();assert blob[:4]==b'PSPO';assert unpack('i',blob,4)[0]==2117
 pos=8;first=None;count=0
 while pos<len(blob):
  tag=blob[pos:pos+4];size=unpack('i',blob,pos+4)[0];payload=blob[pos+8:pos+8+size]
  assert len(payload)==size
  if tag==b'OBJ2':
   count+=1
   if first is None:first=payload
  pos+=8+size
 assert pos==len(blob) and count==3
 p=60
 for _ in range(2):l=unpack('i',first,p)[0];p+=4+l
 p+=12;sz=unpack('i',first,p)[0];tree=first[p+4:];assert len(tree)==sz
 nv,nn,offset=unpack('iii',tree,8);assert nv==nn and nv<65536
 vertices=[unpack('3f',tree,offset+i*24) for i in range(nv)]
 ids=[tuple(round(v,2) for v in p) for p in vertices]
 def walk(at):
  global triangles
  op,size=unpack('ii',tree,at)
  if op==4:
   front,back=unpack('ii',tree,at+36)
   walk(at+front);walk(at+back)
  elif op==5:
   at+=32
   while unpack('i',tree,at)[0]!=0:
    op,size=unpack('ii',tree,at);assert op==3
    points=[unpack('HHff',tree,at+44+i*12)[0] for i in range(3)]
    assert len(set(points))==3
    a,b,c=[vertices[i] for i in points]
    u=[b[k]-a[k] for k in range(3)];v=[c[k]-a[k] for k in range(3)]
    normal=(u[1]*v[2]-u[2]*v[1],u[2]*v[0]-u[0]*v[2],u[0]*v[1]-u[1]*v[0])
    assert sum(normal[k]*a[k] for k in range(3))>0,'Inward or degenerate triangle'
    pids=[ids[i] for i in points]
    for a,b in zip(pids,pids[1:]+pids[:1]):edges[tuple(sorted((a,b)))]+=1;directions[(a,b)]+=1
    triangles+=1;at+=size
  else:raise AssertionError(op)
 walk(unpack('i',tree,4)[0])
assert all(v==2 for v in edges.values()),'Open edge or unmatched cube seam'
assert all(directions[(a,b)]==directions[(b,a)] for a,b in edges),'Inconsistent winding'
assert triangles==442368
for p in (DATA/'maps').glob('ss_p_*-normal.png'):
 im=Image.open(p);assert im.mode=='RGBA';assert im.getchannel('A').getextrema()[0]<200,'Normal X must be stored in alpha (FSO DXT5nm contract)'
assert Image.open(DATA/'maps/ss_p_north.png').size==(8192,8192)
log=(ROOT/'artifacts/planet/validation-m1max.txt').read_text()
assert log.count(' START ')==1 and log.count('RAY_HIT')==5
assert 'RESULT status=PASS' in log and 'NATIVE_COLLISION' in log
assert float(re.search(r'NATIVE_RESPONSE clearance=([-\d.]+)',log)[1])>0
assert 'altitude=100' in log and 'mission=_SPT_Planet_Auto' in log
script=(DATA/'tables/spacesim-planet-sct.lua').read_text()
assert not re.search(r'\.Position\s*=',script),'Player must never be teleported'
assert log.count('AUTO_DONE')==1
assert 'CRUISE speed=1500' in log,'F9 must have been exercised in the engine'
print(f'PASS: {triangles:,} native POF triangles; closed globe and matched seams; outward winding; 8K atlas; DXT5nm normals; 5 native rays; native collision; continuous 100 km ascent; F9 control.')
