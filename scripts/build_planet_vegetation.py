"""Aurore 03 vegetation: hundreds of thousands of trees and boulders, placed where the terrain
shader paints forest and rock (same 3D noise volume, same rules), grouped into 1.5 km sectors.

FSO allows 300 models per mission, so every sector is ONE model made of many sub-objects
(<= 65 535 vertices each), with four detail levels:
  LOD0 full trees (conifers, broadleaf) and boulders   - near
  LOD1 simplified cones / crowns                         - mid range
  LOD2 three-triangle pyramids                           - far
  LOD3 empty                                             - beyond
Usage: build_planet_vegetation.py [--spacing 11] [--density 1.0] [--jobs 9]
"""
from pathlib import Path
import json, math, sys, time
from concurrent.futures import ProcessPoolExecutor
import numpy as np
from PIL import Image
from build_planet import R, DATA, ROOT
from build_planet_tiles import elevation
from build_terrain import pack, vec, string, chunk, bsp, bounds

ARGS = sys.argv
SPACING = float(ARGS[ARGS.index('--spacing') + 1]) if '--spacing' in ARGS else 11.0
DENSITY = float(ARGS[ARGS.index('--density') + 1]) if '--density' in ARGS else 1.0
JOBS = int(ARGS[ARGS.index('--jobs') + 1]) if '--jobs' in ARGS else 9
BOXES = '--boxes' in ARGS
SECTOR = 1500.0
CENTER = np.array([0.0, -R, 0.0])
VERT_LIMIT = 60000

# ---------------------------------------------------------------- the shader's noise volume
def load_volume():
    a = np.asarray(Image.open(DATA / 'maps/ss_air-trans-misc.png').convert('RGBA'), np.float32) / 255.0
    vol = np.zeros((128, 128, 128, 4), np.float32)
    for z in range(128):
        r, c = divmod(z, 16)
        tile = a[r * 130 + 1:r * 130 + 129, c * 130 + 1:c * 130 + 129]   # rows = y, cols = x
        vol[:, :, z] = tile.transpose(1, 0, 2)
    return vol
VOL = None
def tex3(p):
    """Trilinear, wrapping sample exactly like ss_tex3() (texel centres at voxel + 0.5)."""
    q = (p - np.floor(p)) * 128.0 - 0.5
    i0 = np.floor(q).astype(np.int64); f = q - i0
    out = np.zeros(p.shape[:-1] + (4,), np.float32)
    for dx in (0, 1):
        for dy in (0, 1):
            for dz in (0, 1):
                w = (f[..., 0] if dx else 1 - f[..., 0]) * (f[..., 1] if dy else 1 - f[..., 1]) * (f[..., 2] if dz else 1 - f[..., 2])
                out += VOL[(i0[..., 0] + dx) % 128, (i0[..., 1] + dy) % 128, (i0[..., 2] + dz) % 128] * w[..., None]
    return out
def smoothstep(a, b, x):
    t = np.clip((x - a) / (b - a), 0, 1); return t * t * (3 - 2 * t)

# ---------------------------------------------------------------- terrain (vectorised)
def surface(x, z):
    d = np.stack([x, np.full_like(x, R), z], -1); d /= np.linalg.norm(d, axis=-1, keepdims=True)
    for _ in range(2):
        h = elevation(d); p = CENTER + d * (R + h)[..., None]
        d = np.stack([x, p[..., 1] + R, z], -1); d /= np.linalg.norm(d, axis=-1, keepdims=True)
    h = elevation(d)
    return CENTER + d * (R + h)[..., None], d, h

def valley_x(z):
    return 650 * np.sin(z / 2700) + 180 * np.sin(z / 730)

def candidates(rng):
    """Jittered grid over the valley corridor, kept where the shader paints forest / rock."""
    zs = np.arange(-9000, 9000, SPACING); xs = np.arange(-4800, 4800, SPACING)
    Z, X = np.meshgrid(zs, xs, indexing='ij')
    X = X + valley_x(Z) + rng.uniform(-0.45, 0.45, X.shape) * SPACING
    Z = Z + rng.uniform(-0.45, 0.45, Z.shape) * SPACING
    X, Z = X.ravel(), Z.ravel()
    p, up, h = surface(X, Z)
    px, _, _ = surface(X + 5, Z); pz, _, _ = surface(X, Z + 5)
    n = np.cross(pz - p, px - p); n /= np.linalg.norm(n, axis=-1, keepdims=True)
    n *= np.sign(np.sum(n * up, -1))[:, None]
    slope = 1 - np.sum(n * up, -1)
    Pc = p - CENTER
    n1, n2, n3 = tex3(Pc / 3100.0), tex3(Pc / 430.0), tex3(Pc / 57.0)
    rockW = smoothstep(0.16 + 0.10 * (n2[:, 3] - 0.5), 0.30, slope)
    vegLine = 1600 + 700 * (n1[:, 3] - 0.5)
    vegW = (1 - smoothstep(vegLine - 350, vegLine + 250, h)) * (1 - rockW)
    meadow = smoothstep(0.35, 0.75, n2[:, 0] * 0.7 + n1[:, 1] * 0.3)
    sandW = 1 - smoothstep(3, 24, h + 14 * (n3[:, 0] - 0.5))
    snowLine = 2250 + 800 * (n1[:, 0] - 0.5)
    snow = smoothstep(snowLine - 120, snowLine + 160, h)
    clearing = smoothstep(0.30, 0.45, n3[:, 2])                      # glades and edges
    p_tree = vegW * (1 - meadow) ** 0.8 * (1 - sandW) * (1 - snow) * clearing * DENSITY
    p_tree += vegW * meadow * 0.06 * DENSITY                          # isolated trees in meadows
    p_rock = rockW * (1 - snow) * 0.035 * DENSITY + vegW * 0.003 * DENSITY
    r = rng.uniform(0, 1, X.shape)
    tree = (r < p_tree) & (slope < 0.62) & (h > 4)
    rock = (~tree) & (rng.uniform(0, 1, X.shape) < p_rock) & (h > 2)
    broad = tree & (h < 950) & (rng.uniform(0, 1, X.shape) < 0.35 + 0.5 * meadow)
    return dict(p=p, up=up, h=h, tree=tree, rock=rock, broad=broad, shade=n3[:, 1])

# ---------------------------------------------------------------- geometry (world offsets)
class Group:
    def __init__(s): s.v = []; s.f = []; s.uv = []; s.t = []
    def add(s, verts, faces, uvs, tid):
        b = len(s.v); s.v += verts; s.uv += uvs; s.f += [(b + i, b + j, b + k) for i, j, k in faces]; s.t += [tid] * len(faces)

def ring_frame(up, seed):
    a = np.array([math.sin(seed), 0.0, math.cos(seed)]); a -= up * np.dot(a, up); a /= np.linalg.norm(a)
    return a, np.cross(up, a)

def frustum(base, up, r0, r1, y0, y1, n, u0, u1, ax, bx):
    """Shared ring vertices -> smooth vertex normals (rounded cones, no facets)."""
    verts, faces, uvs = [], [], []
    mid = base + up * ((y0 + y1) / 2)
    for k in range(n + 1):
        a = 2 * math.pi * k / n; c = ax * math.cos(a) + bx * math.sin(a); u = u0 + (u1 - u0) * k / n
        verts += [tuple(base + up * y0 + c * r0), tuple(base + up * y1 + c * r1)]; uvs += [(u, 1.0), (u, 0.0)]
    for k in range(n):
        i0, i1, j0, j1 = 2 * k, 2 * k + 1, 2 * k + 2, 2 * k + 3
        q0, q1, q2 = np.array(verts[i0]), np.array(verts[j0]), np.array(verts[j1])
        if np.dot(np.cross(q1 - q0, q2 - q0), (q0 + q2) / 2 - mid) >= 0: faces += [(i0, j0, j1), (i0, j1, i1)]
        else: faces += [(i0, j1, j0), (i0, i1, j1)]
    return verts, faces, uvs

def crown(base, up, rad, y, ax, bx, u0, u1, seed):
    """Low-poly broadleaf crown: displaced, squashed icosahedron (20 faces)."""
    t = (1 + 5 ** 0.5) / 2
    V = np.array([(-1, t, 0), (1, t, 0), (-1, -t, 0), (1, -t, 0), (0, -1, t), (0, 1, t), (0, -1, -t), (0, 1, -t), (t, 0, -1), (t, 0, 1), (-t, 0, -1), (-t, 0, 1)], float)
    V /= np.linalg.norm(V, axis=1, keepdims=True)
    F = [(0, 11, 5), (0, 5, 1), (0, 1, 7), (0, 7, 10), (0, 10, 11), (1, 5, 9), (5, 11, 4), (11, 10, 2), (10, 7, 6), (7, 1, 8), (3, 9, 4), (3, 4, 2), (3, 2, 6), (3, 6, 8), (3, 8, 9), (4, 9, 5), (2, 4, 11), (6, 2, 10), (8, 6, 7), (9, 8, 1)]
    jitter = 0.82 + 0.36 * np.abs(np.sin(np.arange(12) * 12.9898 + seed * 78.233))
    c = base + up * y
    pts = [c + (ax * v[0] + up * v[1] * 0.78 + bx * v[2]) * rad * j for v, j in zip(V, jitter)]
    verts = [tuple(x) for x in pts]
    uvs = [(u0 + (u1 - u0) * (0.5 + 0.5 * v[0]), float(0.5 - 0.45 * v[1])) for v in V]   # v: 0.95 bottom .. 0.05 top
    faces = []
    for a, b, d in F:
        nrm = np.cross(pts[b] - pts[a], pts[d] - pts[a])
        faces.append((a, b, d) if np.dot(nrm, (pts[a] + pts[b] + pts[d]) / 3 - c) > 0 else (a, d, b))
    return verts, faces, uvs

def tree_lods(base, up, hgt, seed, broad, shade):
    ax, bx = ring_frame(up, seed)
    band = int(shade * 3.99); u0, u1 = band * 0.25 + 0.02, band * 0.25 + 0.23    # colour variety per tree
    lod0, lod1, lod2 = [], [], []
    trunk = frustum(base, up, hgt * 0.035, hgt * 0.022, -2.0, hgt * (0.45 if broad else 0.3), 4, 0, 1, ax, bx)
    lod0.append((trunk, 1))
    if broad:
        lod0.append((crown(base, up, hgt * 0.36, hgt * 0.66, ax, bx, u0, u1, seed), 0))
        lod1.append((crown(base, up, hgt * 0.38, hgt * 0.64, ax, bx, u0, u1, seed + 1), 0))
    else:
        for y0, w in ((0.22, 0.29), (0.52, 0.20)):          # 2 tiers (memory: ~1 KB of GPU buffer per triangle in FSO)
            lod0.append((frustum(base, up, hgt * w, 0.03, hgt * y0, hgt * (y0 + 0.46), 6, u0, u1, ax, bx), 0))
        lod1.append((frustum(base, up, hgt * 0.27, 0.02, hgt * 0.10, hgt, 5, u0, u1, ax, bx), 0))
    # LOD2: three-triangle pyramid
    tip = base + up * hgt; w = hgt * 0.26
    c = [base + up * (hgt * 0.15) + (ax * math.cos(k * 2.094) + bx * math.sin(k * 2.094)) * w for k in range(3)]
    verts = [tuple(v) for v in (c[0], c[1], tip, c[1], c[2], tip, c[2], c[0], tip)]
    faces = []
    for i in (0, 3, 6):
        a_, b_, t_ = np.array(verts[i]), np.array(verts[i + 1]), np.array(verts[i + 2])
        faces.append((i, i + 1, i + 2) if np.dot(np.cross(b_ - a_, t_ - a_), (a_ + b_) / 2 - (base + up * hgt * 0.5)) > 0 else (i, i + 2, i + 1))
    lod2.append(((verts, faces, [(u0, 1), (u1, 1), ((u0 + u1) / 2, 0)] * 3), 0))
    return lod0, lod1, lod2

def boulder_lods(base, up, size, seed):
    ax, bx = ring_frame(up, seed)
    t = (1 + 5 ** 0.5) / 2
    V = np.array([(-1, t, 0), (1, t, 0), (-1, -t, 0), (1, -t, 0), (0, -1, t), (0, 1, t), (0, -1, -t), (0, 1, -t), (t, 0, -1), (t, 0, 1), (-t, 0, -1), (-t, 0, 1)], float)
    F = [(0, 11, 5), (0, 5, 1), (0, 1, 7), (0, 7, 10), (0, 10, 11), (1, 5, 9), (5, 11, 4), (11, 10, 2), (10, 7, 6), (7, 1, 8), (3, 9, 4), (3, 4, 2), (3, 2, 6), (3, 6, 8), (3, 8, 9), (4, 9, 5), (2, 4, 11), (6, 2, 10), (8, 6, 7), (9, 8, 1)]
    def build(V, F):
        V = V / np.linalg.norm(V, axis=1, keepdims=True)
        j = 0.7 + 0.6 * np.abs(np.sin(V @ np.array([12.9898, 78.233, 37.719]) + seed))
        c = base + up * size * 0.3
        pts = [c + (ax * v[0] + up * v[1] * 0.6 + bx * v[2]) * size * k for v, k in zip(V, j)]
        verts, faces, uvs = [tuple(p) for p in pts], [], [(float(v[0] * .5 + .5), float(v[1] * .5 + .5)) for v in V]
        for a, b, d in F:
            nrm = np.cross(pts[b] - pts[a], pts[d] - pts[a])
            faces.append((a, b, d) if np.dot(nrm, (pts[a] + pts[b] + pts[d]) / 3 - c) > 0 else (a, d, b))
        return verts, faces, uvs
    # one subdivision for LOD0
    cache = {}; V2 = list(V); F2 = []
    def mid(a, b):
        k = (min(a, b), max(a, b))
        if k not in cache: V2.append((V[a] + V[b]) / 2); cache[k] = len(V2) - 1
        return cache[k]
    for a, b, d in F:
        ab, bd, da = mid(a, b), mid(b, d), mid(d, a); F2 += [(a, ab, da), (b, bd, ab), (d, da, bd), (ab, bd, da)]
    # memory (FSO keeps buffers + a collision tree per submodel): small stones keep the 20-face shape
    if size < 3.5: return [(build(V, F), 0)], [(build(V, F), 0)], []
    return [(build(np.array(V2), F2), 0)], [(build(V, F), 0)], []

# ---------------------------------------------------------------- POF with many sub-objects per LOD
CHUNK = 750.0          # detail-box cell size (m): few draw calls
NEAR_BOX = 400.0       # full trees while the camera is within this distance of a cell
def write_sector(path, lods, textures):
    """lods: list of lists of (Group, props). Element 0 of each LOD is its root; others become children."""
    subs = []; roots = []
    for li, items in enumerate(lods):
        if not items:
            g = Group(); g.add([(0, -60, 0), (0.01, -60, 0), (0, -60, 0.01)], [(0, 2, 1)], [(0, 0)] * 3, 0); items = [(g, '')]
        root = len(subs); roots.append(root)
        for k, (g, props) in enumerate(items):
            subs.append((len(subs), -1 if k == 0 else root, g, f'detail{li}' if k == 0 else f'detail{li}-{k}', props))
    allv = [v for _, _, g, _, _ in subs for v in g.v]
    lo, hi = bounds(allv); radius = max(math.sqrt(sum(t * t for t in v)) for v in allv)
    hdr = pack('fii', radius, 0, len(subs)) + vec(lo) + vec(hi) + pack('i', len(roots)) + pack('i' * len(roots), *roots) + pack('i', 0)
    hdr += pack('f', 1e12) + vec((0, 0, 0)) + vec((.001, 0, 0)) + vec((0, .001, 0)) + vec((0, 0, .001)) + pack('ii', 0, 0)
    data = b'PSPO' + pack('i', 2117) + chunk('HDR2', hdr)
    for idx, parent, g, name, props in subs:
        slo, shi = bounds(g.v); srad = max(math.sqrt(sum(t * t for t in v)) for v in g.v)
        tree = bsp(g.v, g.f, g.uv, g.t)
        data += chunk('OBJ2', pack('ifi', idx, srad, parent) + vec((0, 0, 0)) + vec((0, 0, 0)) + vec(slo) + vec(shi) + string(name) + string(props) + pack('iii', 0, -1, 0) + pack('i', len(tree)) + tree)
    data += chunk('TXTR', pack('i', len(textures)) + b''.join(string(t) for t in textures))
    path.write_bytes(data)

def pack_groups(items):
    groups = [Group()]
    for verts, faces, uvs, tid in items:
        if len(groups[-1].v) + len(verts) > VERT_LIMIT: groups.append(Group())
        groups[-1].add(verts, faces, uvs, tid)
    return [g for g in groups if g.f]

def box_props(sign, lo, hi):
    return (f'$detail_box: {sign}\n$box_min: {lo[0]:.1f},{lo[1]:.1f},{lo[2]:.1f}\n'
            f'$box_max: {hi[0]:.1f},{hi[1]:.1f},{hi[2]:.1f}\n$do_not_scale_distances\n')

def build_sector(job):
    key, p0, trees, rocks = job
    cells = {}
    far = []
    tris = [0, 0, 0]
    def cell_of(b):
        return (int(math.floor(b[0] / CHUNK)), int(math.floor(b[2] / CHUNK)))
    for base, up, hgt, seed, broad, shade in trees:
        b = np.array(base) - p0
        a, l1, l2 = tree_lods(b, np.array(up), hgt, seed, broad, shade)
        c = cells.setdefault(cell_of(b), ([], [], []))
        for (v, f, u), tid in a: c[0].append((v, f, u, tid))
        for (v, f, u), tid in l1: c[1].append((v, f, u, tid))
        for (v, f, u), tid in l2: far.append((v, f, u, tid))
        c[2].append(b)
    for base, up, size, seed in rocks:
        b = np.array(base) - p0
        a, l1, _ = boulder_lods(b, np.array(up), size, seed)
        c = cells.setdefault(cell_of(b), ([], [], []))
        for (v, f, u), tid in a: c[0].append((v, f, u, 2))
        if size > 3.5:
            for (v, f, u), tid in l1: c[1].append((v, f, u, 2))
        c[2].append(b)
    full = [i for c in cells.values() for i in c[0]]; lite = [i for c in cells.values() for i in c[1]]
    if BOXES:
        # Per-cell detail boxes: full trees only within NEAR_BOX of their 750 m cell, cones elsewhere.
        # FSO 26.2 also honours detail boxes in the shadow pass (shadows.cpp, add_model_draws + view_pos),
        # which is where most of the vegetation cost is (4 cascades).
        lod0 = [(Group(), '')]
        lod0[0][0].add([(0, -60, 0), (0.01, -60, 0), (0, -60, 0.01)], [(0, 2, 1)], [(0, 0)] * 3, 0)
        for (cx, cz), (cf, cl, pts) in cells.items():
            P = np.array(pts)
            lo = (P[:, 0].min() - NEAR_BOX, P[:, 1].min() - 900.0, P[:, 2].min() - NEAR_BOX)
            hi = (P[:, 0].max() + NEAR_BOX, P[:, 1].max() + 900.0, P[:, 2].max() + NEAR_BOX)
            for g in pack_groups(cf): lod0.append((g, box_props(1, lo, hi)))
            for g in pack_groups(cl): lod0.append((g, box_props(-1, lo, hi)))
        lods = [lod0, [(g, '') for g in pack_groups(lite)], [(g, '') for g in pack_groups(far)], []]
    else:
        # Whole-sector levels: full trees, simplified trees, pyramids, nothing.
        lods = [[(g, '') for g in pack_groups(full)], [(g, '') for g in pack_groups(lite)], [(g, '') for g in pack_groups(far)], []]
    tris = [sum(len(f) for _, f, _, _ in full), sum(len(f) for _, f, _, _ in lite), sum(len(f) for _, f, _, _ in far)]
    name = f'ss_v_{key}'
    write_sector(DATA / 'models' / f'{name}.pof', lods, ['ss_foliage', 'ss_bark', 'ss_rock'])
    return dict(name=name, pos=[float(c) for c in p0], trees=len(trees), rocks=len(rocks), tris=tris, cells=len(cells))

def foliage_texture():
    """Four colour bands (U) so neighbouring trees differ: dark spruce, blue-green, fresh green, autumn."""
    S = 256; y, x = np.mgrid[0:S, 0:S].astype(np.float32)
    rng = np.random.default_rng(5)
    n = rng.random((S, S)).astype(np.float32)
    from PIL import ImageFilter
    n = np.asarray(Image.fromarray(np.uint8(n * 255)).filter(ImageFilter.GaussianBlur(1.2)), np.float32) / 255
    bands = np.array([[0.06, 0.12, 0.05], [0.06, 0.13, 0.10], [0.11, 0.19, 0.06], [0.26, 0.16, 0.06]], np.float32)
    col = bands[np.clip((x / S * 4).astype(int), 0, 3)]
    col = col * (0.55 + 0.8 * n[..., None]) * (0.75 + 0.35 * (1 - y / S))[..., None]
    img = np.uint8(np.clip(col, 0, 1) * 255); img[0, 0] = (9, 11, 13)          # foliage marker for main-f.sdr
    Image.fromarray(img).save(DATA / 'maps/ss_foliage.png')

def main():
    global VOL
    t0 = time.time()
    VOL = load_volume()
    foliage_texture()
    rng = np.random.default_rng(42)
    c = candidates(rng)
    ground = json.loads((ROOT / 'artifacts/planet/ground.json').read_text())
    keep_out = [(s['pos'][0], s['pos'][2], 90.0) for s in ground['ships']] + [(p['pos'][0], p['pos'][2], 80.0) for p in ground['props'] if not p['name'].startswith('Nature')]
    P = c['p']; ok = np.ones(len(P), bool)
    for x, z, r in keep_out: ok &= (P[:, 0] - x) ** 2 + (P[:, 2] - z) ** 2 > r * r
    tree_idx = np.where(c['tree'] & ok)[0]; rock_idx = np.where(c['rock'] & ok)[0]
    print(f'{len(P):,} candidates -> {len(tree_idx):,} trees, {len(rock_idx):,} boulders ({time.time()-t0:.0f}s)', flush=True)
    sectors = {}
    def key_of(i):
        return (int(math.floor(P[i, 0] / SECTOR)), int(math.floor(P[i, 2] / SECTOR)))
    for i in tree_idx:
        k = key_of(i); sec = sectors.setdefault(k, ([], []))
        hgt = float(rng.uniform(9, 27) * (0.75 if c['broad'][i] else 1.0))
        sec[0].append((P[i].tolist(), c['up'][i].tolist(), hgt, float(rng.uniform(0, 6.28)), bool(c['broad'][i]), float(c['shade'][i])))
    for i in rock_idx:
        k = key_of(i); sec = sectors.setdefault(k, ([], []))
        size = float(rng.uniform(1.2, 7) if rng.uniform() < 0.9 else rng.uniform(8, 18))
        sec[1].append((P[i].tolist(), c['up'][i].tolist(), size, float(rng.uniform(0, 6.28))))
    jobs = []
    for (kx, kz), (trees, rocks) in sectors.items():
        if len(trees) + len(rocks) < 20: continue
        pts = np.array([t[0] for t in trees] + [r[0] for r in rocks])
        p0 = pts.mean(0)
        jobs.append((f'{kx + 20:02d}{kz + 20:02d}', p0, trees, rocks))
    for old in (DATA / 'models').glob('ss_v_*.pof'): old.unlink()
    out = []
    with ProcessPoolExecutor(JOBS, initializer=_init) as ex:
        for i, r in enumerate(ex.map(build_sector, jobs)):
            out.append(r)
            if i % 10 == 0: print(f'  sector {i+1}/{len(jobs)} {r["name"]}: {r["trees"]} trees, {r["rocks"]} rocks, LOD0 {r["tris"][0]:,} tris', flush=True)
    (ROOT / 'artifacts/planet/vegetation.json').write_text(json.dumps(out, indent=1))
    T = sum(r['trees'] for r in out); B = sum(r['rocks'] for r in out)
    print(f'Vegetation: {len(out)} sectors, {T:,} trees, {B:,} boulders, full {sum(r["tris"][0] for r in out):,} tris, lite {sum(r["tris"][1] for r in out):,}, far {sum(r["tris"][2] for r in out):,}, cells {sum(r["cells"] for r in out)} ({time.time()-t0:.0f}s)')

def _init():
    global VOL
    VOL = None

if __name__ == '__main__':
    main()
