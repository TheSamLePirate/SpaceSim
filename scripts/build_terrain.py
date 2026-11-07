"""Build an original closed terrain mesh and a legacy-compatible FSO POF.

The chunk layout follows FSO 26.2 modelread.cpp/modelcollide.cpp. BSP nodes
are spatially partitioned, so ray/ship collision tests do not scan every face.
No third-party model or texture is copied into the terrain package.
"""
from pathlib import Path
import json
import math
import random
import struct
import zlib

ROOT = Path(__file__).resolve().parent.parent
DATA = ROOT / 'mods/terrain/data'
HALF = 4000.0
BOTTOM = -350.0
GRID = 96


def height(x, z):
    center = 240 * math.sin(z / 1150)
    d = abs(x - center)
    ridge = 1050 * (1 - math.exp(-(d / 1000) ** 2))
    floor = 55 + 26 * math.sin(z / 470) + 12 * math.cos(x / 340)
    rough = (25 * math.sin(x / 180 + z / 230) + 14 * math.cos(z / 130)) * min(1, d / 550)
    peaks = 270 * math.exp(-((x - 1850) ** 2 + (z - 900) ** 2) / 550000)
    return floor + ridge + rough + peaks


def pack(fmt, *values):
    return struct.pack('<' + fmt, *values)


def vec(v):
    return pack('3f', *v)


def string(s):
    data = s.encode('ascii')
    return pack('i', len(data)) + data


def chunk(tag, payload):
    return tag.encode('ascii') + pack('i', len(payload)) + payload


def normalize(v):
    length = math.sqrt(sum(a*a for a in v))
    if length < 1e-8:
        raise ValueError('Degenerate triangle')
    return tuple(a / length for a in v)


def face_normal(a, b, c):
    u, v = [b[i]-a[i] for i in range(3)], [c[i]-a[i] for i in range(3)]
    return normalize((u[1]*v[2]-u[2]*v[1], u[2]*v[0]-u[0]*v[2], u[0]*v[1]-u[1]*v[0]))


def bounds(vertices):
    return tuple(min(v[k] for v in vertices) for k in range(3)), tuple(max(v[k] for v in vertices) for k in range(3))


def terrain_mesh(n):
    vertices = []
    for iz in range(n+1):
        z = -HALF + 2 * HALF * iz / n
        for ix in range(n+1):
            x = -HALF + 2 * HALF * ix / n
            vertices.append((x, height(x, z), z))
    faces = []
    for iz in range(n):
        for ix in range(n):
            a = iz*(n+1)+ix
            b, c, d = a+1, a+n+1, a+n+2
            faces.extend([(a,c,b), (b,c,d)])
    # Ordered around the outer edge; add walls and a bottom to close the volume.
    edge = list(range(n+1))
    edge += [iz*(n+1)+n for iz in range(1,n+1)]
    edge += [n*(n+1)+ix for ix in range(n-1,-1,-1)]
    edge += [iz*(n+1) for iz in range(n-1,0,-1)]
    bottom_indices = []
    for i in edge:
        x, _, z = vertices[i]
        bottom_indices.append(len(vertices))
        vertices.append((x, BOTTOM, z))
    for k in range(len(edge)):
        j = (k+1) % len(edge)
        a,b,c,d = edge[k],edge[j],bottom_indices[k],bottom_indices[j]
        faces.extend([(a,b,c), (b,d,c)])
    bottom_center = len(vertices)
    vertices.append((0, BOTTOM, 0))
    for k in range(len(edge)):
        faces.append((bottom_center,bottom_indices[k],bottom_indices[(k+1)%len(edge)]))
    return vertices, faces


def bsp(vertices, faces, uv_coords=None, texture_ids=None):
    accum = [[0.,0.,0.] for _ in vertices]
    records = []
    for face_index, ids in enumerate(faces):
        points = [vertices[i] for i in ids]
        normal = face_normal(*points)
        center = tuple(sum(p[k] for p in points)/3 for k in range(3))
        radius = max(math.dist(p, center) for p in points)
        uv = [uv_coords[i] if uv_coords is not None else ((vertices[i][0]+HALF)/(2*HALF), (vertices[i][2]+HALF)/(2*HALF)) for i in ids]
        payload = vec(normal)+vec(center)+pack('fii',radius,3,texture_ids[face_index] if texture_ids is not None else 0)
        payload += b''.join(pack('HHff', i,i,*tex) for i,tex in zip(ids,uv))
        records.append((ids,center,pack('ii',3,len(payload)+8)+payload))
        for i in ids:
            for k in range(3): accum[i][k] += normal[k]
    normals = [normalize(v) for v in accum]
    point_offset = (20+len(vertices)+3)//4*4
    header = pack('iii',len(vertices),len(vertices),point_offset)
    header += bytes([1])*len(vertices)
    header += b'\0'*(point_offset-8-len(header))
    payload = header+b''.join(vec(v)+vec(n) for v,n in zip(vertices,normals))
    definitions = pack('ii',1,len(payload)+8)+payload
    eof = pack('ii',0,0)
    def node(items, depth=0):
        indices = {i for ids,_,_ in items for i in ids}
        lo,hi = bounds([vertices[i] for i in indices])
        # Give flat bottom leaves a nonzero bounding box thickness.
        lo = tuple(v-.01 for v in lo)
        hi = tuple(v+.01 for v in hi)
        if len(items) <= 32:
            return pack('ii',5,32)+vec(lo)+vec(hi)+b''.join(item[2] for item in items)+eof
        axis = max(range(3), key=lambda k:hi[k]-lo[k])
        items = sorted(items,key=lambda item:item[1][axis])
        cut = len(items)//2
        front,back = node(items[:cut],depth+1),node(items[cut:],depth+1)
        normal = tuple(1. if k==axis else 0. for k in range(3))
        center = tuple((lo[k]+hi[k])/2 for k in range(3))
        payload = vec(normal)+vec(center)+pack('6i',0,80,80+len(front),0,0,0)+vec(lo)+vec(hi)
        assert len(payload)==72
        return pack('ii',4,80+len(front)+len(back))+payload+front+back+eof
    return definitions+node(records)


def write_pof(path, grids):
    meshes = [terrain_mesh(n) for n in grids]
    lo,hi = bounds(meshes[0][0])
    radius = max(math.sqrt(sum(t*t for t in v)) for v in meshes[0][0])
    header = pack('fii',radius,0,len(meshes))+vec(lo)+vec(hi)
    header += pack('i',len(meshes))+pack('i'*len(meshes),*range(len(meshes)))+pack('i',0)
    header += pack('f',1e9)+vec((0,0,0))+vec((.001,0,0))+vec((0,.001,0))+vec((0,0,.001))
    header += pack('ii',0,0)
    data = b'PSPO'+pack('i',2117)+chunk('HDR2',header)
    for i,(vertices,faces) in enumerate(meshes):
        tree = bsp(vertices,faces)
        payload = pack('ifi',i,radius,-1)+vec((0,0,0))+vec((0,0,0))+vec(lo)+vec(hi)
        payload += string(f'detail{i}')+string('')+pack('iii',0,-1,0)+pack('i',len(tree))+tree
        data += chunk('OBJ2',payload)
    data += chunk('TXTR',pack('i',1)+string('ss_terrain'))
    data += chunk('PINF',b'SpaceSim original procedural terrain; FSO 26.2; metres.\0')
    path.write_bytes(data)
    return {'vertices':len(meshes[0][0]),'triangles':len(meshes[0][1]),'lods':grids,'bounds':[lo,hi],'radius_m':radius,'pof_bytes':len(data)}


def png(path, width, height_, rgb):
    def section(kind,data):
        return struct.pack('>I',len(data))+kind+data+struct.pack('>I',zlib.crc32(kind+data)&0xffffffff)
    raw = b''.join(b'\0'+bytes(rgb[y*width*3:(y+1)*width*3]) for y in range(height_))
    path.write_bytes(b'\x89PNG\r\n\x1a\n'+section(b'IHDR',struct.pack('>IIBBBBB',width,height_,8,2,0,0,0))+section(b'IDAT',zlib.compress(raw,8))+section(b'IEND',b''))


def texture():
    random.seed(2117)
    size = 1024
    rgb = bytearray()
    for iz in range(size):
        z = -HALF+2*HALF*iz/(size-1)
        for ix in range(size):
            x = -HALF+2*HALF*ix/(size-1)
            h = height(x,z)
            slope = math.hypot((height(x+8,z)-height(x-8,z))/16,(height(x,z+8)-height(x,z-8))/16)
            rock = min(1,max(0,(h-160)/900 + slope*.22))
            sand = (176,137,94)
            stone = (108,112,119)
            grain = random.uniform(-12,12)+5*math.sin(x/18+z/25)+4*math.sin(h/14)
            for a,b in zip(sand,stone):rgb.append(int(max(0,min(255,a*(1-rock)+b*rock+grain))))
    png(DATA/'maps/ss_terrain.png',size,size,rgb)


def main():
    for name in ['models','maps','tables','missions']:(DATA/name).mkdir(parents=True,exist_ok=True)
    info = write_pof(DATA/'models/ss_terrain.pof',[GRID,32])
    texture()
    info.update({'width_m':8000,'depth_m':8000,'height_function':'height(x,z) in scripts/build_terrain.py','format':'PSPO 2117, textured BSP, closed mesh','source':'original generated geometry and texture'})
    (ROOT/'artifacts/terrain/geometry.json').write_text(json.dumps(info,indent=2)+'\n')
    print(json.dumps(info,indent=2))

if __name__=='__main__':main()
