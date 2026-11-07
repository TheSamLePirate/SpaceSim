"""Aurore 03 terrain: cube-sphere quadtree of native POF props, finest near the landing site.

Every tile is its own prop placed at its centre (correct culling and LOD), with
3 detail levels, crack-hiding skirts, and native BSP collision on detail 0.
Materials are procedural in main-f.sdr: tiles only carry the 1x1 'ss_ground'
marker texture plus the shared 3D noise volume as '-misc' map.
Usage: build_planet_tiles.py [--cells 160] [--depth 7] [--jobs 8]
"""
from pathlib import Path
import json, math, sys, time
from concurrent.futures import ProcessPoolExecutor
import numpy as np
from PIL import Image
from build_planet import R, FACES, elevation as base_elevation, noise, DATA, ROOT, directions
from build_terrain import pack, vec, string, chunk, bsp, bounds

LANDING = np.array([0.0, 80000.0, -5000.0]) / np.linalg.norm([0.0, 80000.0, -5000.0])
ARGS = sys.argv
CELLS = int(ARGS[ARGS.index('--cells') + 1]) if '--cells' in ARGS else 160
DEPTH = int(ARGS[ARGS.index('--depth') + 1]) if '--depth' in ARGS else 7
JOBS = int(ARGS[ARGS.index('--jobs') + 1]) if '--jobs' in ARGS else 8

def elevation(d):
    """Base relief plus ridged detail down to ~10 m wavelengths (valley floor kept flyable)."""
    h = base_elevation(d)
    x, y, z = [d[..., k] * R for k in range(3)]
    valley_center = 650 * np.sin(z / 2700) + 180 * np.sin(z / 730)
    near_landing = np.exp(-((x / 17000) ** 4 + (z / 23000) ** 4)) * np.clip((d[..., 1] - .75) * 12, 0, 1)
    floor = np.clip((np.abs(x - valley_center) - 250) / 700, 0.12, 1) * near_landing + (1 - near_landing)
    land = np.clip(h / 120, 0, 1)
    det = np.zeros_like(h); w = 520.0; a = 120.0
    for o in range(7):
        r = 1 - np.abs(2 * noise(x / w + 31.7 * o, y / w - 7.3 * o, z / w + 3.1 * o) - 1)
        det += a * (r * r - 0.33)
        w *= 0.5; a *= 0.47
    return np.maximum(0, h + det * land * floor)

def tile_mesh(face, u0, v0, size, n):
    """Grid over a cube-face square, positions relative to the tile centre, plus skirts."""
    ax = np.linspace(0, 1, n + 1)
    u, v = np.meshgrid(u0 + ax * size, v0 + ax * size)
    d = directions(face, u, v)
    h = elevation(d)
    p = d * (R + h)[..., None]
    dc = directions(face, np.array(u0 + size / 2), np.array(v0 + size / 2))
    center = dc * (R + float(elevation(dc[None])[0]))
    verts = (p - center).reshape(-1, 3)
    faces = []
    idx = lambda i, j: j * (n + 1) + i
    a0, b0, c0 = verts[idx(0, 0)], verts[idx(1, 0)], verts[idx(0, 1)]
    outward = np.dot(np.cross(c0 - a0, b0 - a0), p[0, 0]) > 0
    for j in range(n):
        for i in range(n):
            a, b, c, e = idx(i, j), idx(i + 1, j), idx(i, j + 1), idx(i + 1, j + 1)
            faces += [(a, c, b), (b, c, e)] if outward else [(a, b, c), (b, e, c)]
    # Skirts hide T-junction cracks with coarser neighbours.
    spacing = size * R / n
    drop = 25 + 3 * spacing
    ring = [idx(i, 0) for i in range(n)] + [idx(n, j) for j in range(n)] + [idx(i, n) for i in range(n, 0, -1)] + [idx(0, j) for j in range(n, 0, -1)]
    pf = p.reshape(-1, 3); dfl = d.reshape(-1, 3)
    # Skirt uses its own copy of the rim so its faces never bend the surface normals.
    m = len(ring); top0 = len(verts); base = top0 + m
    tops = [verts[vi] for vi in ring]
    bottoms = [pf[vi] - dfl[vi] * drop - center for vi in ring]
    verts = np.vstack([verts, np.array(tops), np.array(bottoms)])
    for k in range(m):
        t0, t1 = top0 + k, top0 + (k + 1) % m; s0, s1 = base + k, base + (k + 1) % m
        q = [(t0, s0, t1), (t1, s0, s1)]
        va, vb, vc = verts[t0], verts[s0], verts[t1]
        nrm = np.cross(vb - va, vc - va)
        mid = (verts[t0] + verts[t1]) / 2
        out_dir = mid - dc * np.dot(mid, dc)            # away from the tile axis
        if np.dot(nrm, out_dir) < 0: q = [(t0, t1, s0), (t1, s1, s0)]
        faces += q
    uv = [(0.5, 0.5)] * len(verts)
    return [tuple(map(float, v)) for v in verts], faces, uv, center

def quadtree():
    tiles = []
    def visit(face, u0, v0, size, depth):
        dc = directions(face, np.array(u0 + size / 2), np.array(v0 + size / 2))
        arc = np.arccos(np.clip(np.dot(dc, LANDING), -1, 1)) * R
        extent = size * R
        if depth < DEPTH and arc < 0.75 * extent + 1500:
            half = size / 2
            for du in (0, half):
                for dv in (0, half):
                    visit(face, u0 + du, v0 + dv, half, depth + 1)
        else:
            tiles.append((face, u0, v0, size, depth))
    for face in FACES:
        visit(face, -1.0, -1.0, 2.0, 0)
    return tiles

def build(job):
    k, (face, u0, v0, size, depth) = job
    name = f'ss_t{k:03d}'
    t = time.time()
    lods = []
    center = None
    for n in (CELLS, CELLS // 2, CELLS // 4):
        vs, fs, uv, c = tile_mesh(face, u0, v0, size, n)
        center = c if center is None else center
        lods.append((vs, fs, uv))
    info = pof_tile(DATA / 'models' / f'{name}.pof', lods)
    extent = size * R
    return dict(name=name, face=face[0], depth=depth, center=[float(x) for x in center],
                grid_m=extent / CELLS, extent_m=extent, seconds=round(time.time() - t, 1), **info)

def pof_tile(path, meshes):
    lo, hi = bounds(meshes[0][0]); radius = max(math.sqrt(sum(t * t for t in v)) for v in meshes[0][0])
    hdr = pack('fii', radius, 0, len(meshes)) + vec(lo) + vec(hi) + pack('i', len(meshes)) + pack('i' * len(meshes), *range(len(meshes))) + pack('i', 0)
    hdr += pack('f', 1e12) + vec((0, 0, 0)) + vec((.001, 0, 0)) + vec((0, .001, 0)) + vec((0, 0, .001)) + pack('ii', 0, 0)
    data = b'PSPO' + pack('i', 2117) + chunk('HDR2', hdr)
    for i, (vs, fs, uv) in enumerate(meshes):
        tree = bsp(vs, fs, uv)
        data += chunk('OBJ2', pack('ifi', i, radius, -1) + vec((0, 0, 0)) + vec((0, 0, 0)) + vec(lo) + vec(hi) + string(f'detail{i}') + string('') + pack('iii', 0, -1, 0) + pack('i', len(tree)) + tree)
    data += chunk('TXTR', pack('i', 1) + string('ss_ground'))
    path.write_bytes(data)
    return dict(vertices=len(meshes[0][0]), triangles=len(meshes[0][1]), radius=radius)

def main():
    tiles = quadtree()
    print(f'{len(tiles)} tiles, depth {DEPTH}, {CELLS} cells', flush=True)
    if '--count' in ARGS: return
    for old in (DATA / 'models').glob('ss_t*.pof'): old.unlink()
    Image.new('RGBA', (1, 1), (3, 5, 7, 255)).save(DATA / 'maps/ss_ground.png')
    misc = DATA / 'maps/ss_air-trans-misc.png'
    (DATA / 'maps/ss_ground-misc.png').write_bytes(misc.read_bytes())
    t = time.time(); out = []
    with ProcessPoolExecutor(JOBS) as ex:
        for i, r in enumerate(ex.map(build, enumerate(tiles))):
            out.append(r)
            if i % 10 == 0: print(f'  {i+1}/{len(tiles)} {r["name"]} grid {r["grid_m"]:.1f} m', flush=True)
    (ROOT / 'artifacts/planet/tiles.json').write_text(json.dumps(out, indent=1))
    print(f'Built {len(out)} tiles, {sum(r["triangles"] for r in out):,} triangles at LOD0, finest grid {min(r["grid_m"] for r in out):.1f} m, {time.time()-t:.0f}s')

if __name__ == '__main__':
    main()
