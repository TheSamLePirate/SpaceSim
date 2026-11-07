"""Aurore 03 ground content: Imperial outpost, rock fields and conifer forests.

Generates native POF props (flat-shaded buildings with procedural concrete/metal
textures and glow-map windows; per-patch boulder fields and forests that follow
the real terrain) and places FotG ships (turbolaser towers, AT-ATs, Lambda,
cargo, beacons). Output: models/maps + artifacts/planet/ground.json, consumed by
create_planet_mission.py.
"""
from pathlib import Path
import json, math, struct
import numpy as np
from PIL import Image, ImageDraw, ImageFilter
from build_planet import R, DATA, ROOT, noise
from build_planet_tiles import elevation
from build_terrain import pack, vec, string, chunk, bsp, bounds

rng = np.random.default_rng(2077)
CENTER = np.array([0.0, -R, 0.0])

# ------------------------------------------------------------------ terrain queries
def surface(x, z):
    """World point on the terrain above planar (x, z) near the pole, and its radial up."""
    d = np.array([x, R, z], float); d /= np.linalg.norm(d)
    for _ in range(3):
        h = float(elevation(d[None])[0]); p = CENTER + d * (R + h)
        d = np.array([x, p[1] + R, z]); d /= np.linalg.norm(d)
    h = float(elevation(d[None])[0])
    return CENTER + d * (R + h), d, h

def slope_at(x, z, e=6.0):
    p0, up, _ = surface(x, z); px, _, _ = surface(x + e, z); pz, _, _ = surface(x, z + e)
    n = np.cross(pz - p0, px - p0); n /= np.linalg.norm(n)
    if np.dot(n, up) < 0: n = -n
    return 1 - float(np.dot(n, up)), n

def valley_x(z):
    return 650 * math.sin(z / 2700) + 180 * math.sin(z / 730)

def frame(up, heading):
    f = np.array([math.sin(heading), 0.0, math.cos(heading)])
    f = f - up * np.dot(f, up); f /= np.linalg.norm(f)
    r = np.cross(up, f)
    return r, up, f

# ------------------------------------------------------------------ mesh building (flat shaded)
class Mesh:
    def __init__(self): self.v = []; self.f = []; self.uv = []; self.t = []
    def quad(self, a, b, c, d, tid, uvs):
        i = len(self.v); self.v += [a, b, c, d]; self.uv += uvs
        self.f += [(i, i + 1, i + 2), (i, i + 2, i + 3)]; self.t += [tid, tid]
    def tri(self, a, b, c, tid, uvs):
        i = len(self.v); self.v += [a, b, c]; self.uv += uvs; self.f.append((i, i + 1, i + 2)); self.t.append(tid)
    def box(self, c, s, tid, tile=8.0):
        cx, cy, cz = c; hx, hy, hz = s[0] / 2, s[1] / 2, s[2] / 2
        P = lambda x, y, z: (cx + x, cy + y, cz + z)
        faces = [  # outward winding (x right, y up, z forward)
            ([P(-hx, -hy, hz), P(hx, -hy, hz), P(hx, hy, hz), P(-hx, hy, hz)], 2 * hx, 2 * hy),
            ([P(hx, -hy, -hz), P(-hx, -hy, -hz), P(-hx, hy, -hz), P(hx, hy, -hz)], 2 * hx, 2 * hy),
            ([P(hx, -hy, hz), P(hx, -hy, -hz), P(hx, hy, -hz), P(hx, hy, hz)], 2 * hz, 2 * hy),
            ([P(-hx, -hy, -hz), P(-hx, -hy, hz), P(-hx, hy, hz), P(-hx, hy, -hz)], 2 * hz, 2 * hy),
            ([P(-hx, hy, hz), P(hx, hy, hz), P(hx, hy, -hz), P(-hx, hy, -hz)], 2 * hx, 2 * hz),
            ([P(-hx, -hy, -hz), P(hx, -hy, -hz), P(hx, -hy, hz), P(-hx, -hy, hz)], 2 * hx, 2 * hz)]
        for q, w, h in faces:
            u, v = w / tile, h / tile
            self.quad(*q, tid, [(0, v), (u, v), (u, 0), (0, 0)])
    def cylinder(self, c, r, h, tid, sides=16, r2=None, cap=True, tile=8.0):
        r2 = r if r2 is None else r2; cx, cy, cz = c
        circ = 2 * math.pi * r / tile
        for k in range(sides):
            a0, a1 = 2 * math.pi * k / sides, 2 * math.pi * (k + 1) / sides
            p0 = (cx + r * math.sin(a0), cy, cz + r * math.cos(a0)); p1 = (cx + r * math.sin(a1), cy, cz + r * math.cos(a1))
            q1 = (cx + r2 * math.sin(a1), cy + h, cz + r2 * math.cos(a1)); q0 = (cx + r2 * math.sin(a0), cy + h, cz + r2 * math.cos(a0))
            u0, u1 = circ * k / sides, circ * (k + 1) / sides
            self.quad(p0, p1, q1, q0, tid, [(u0, h / tile), (u1, h / tile), (u1, 0), (u0, 0)])
            if cap and r2 > 0:
                self.tri((cx, cy + h, cz), q0, q1, tid, [(0.5, 0.5), (0.5 + .5 * math.sin(a0), .5 + .5 * math.cos(a0)), (0.5 + .5 * math.sin(a1), .5 + .5 * math.cos(a1))])
    def vault(self, c, r, length, tid, sides=14, tile=8.0):
        cx, cy, cz = c; L = length / 2
        for k in range(sides):
            a0, a1 = math.pi * k / sides, math.pi * (k + 1) / sides
            y0, x0, y1, x1 = r * math.sin(a0), r * math.cos(a0), r * math.sin(a1), r * math.cos(a1)
            u0, u1 = math.pi * r * k / sides / tile, math.pi * r * (k + 1) / sides / tile
            self.quad((cx + x0, cy + y0, cz - L), (cx + x1, cy + y1, cz - L), (cx + x1, cy + y1, cz + L), (cx + x0, cy + y0, cz + L), tid,
                      [(u0, 0), (u1, 0), (u1, length / tile), (u0, length / tile)])
            self.tri((cx, cy, cz + L), (cx + x0, cy + y0, cz + L), (cx + x1, cy + y1, cz + L), tid, [(0.5, 0), (x0 / r / 2 + .5, y0 / r), (x1 / r / 2 + .5, y1 / r)])
            self.tri((cx, cy, cz - L), (cx + x1, cy + y1, cz - L), (cx + x0, cy + y0, cz - L), tid, [(0.5, 0), (x1 / r / 2 + .5, y1 / r), (x0 / r / 2 + .5, y0 / r)])

EMPTY = ([(0, -80, 0), (0.01, -80, 0), (0, -80, 0.01)], [(0, 2, 1)], [(0, 0)] * 3, [0])   # culled level: one buried sliver
def write_pof(path, mesh, textures, extra_lods=()):
    meshes = [(mesh.v, mesh.f, mesh.uv, mesh.t)] + [l if isinstance(l, tuple) else (l.v, l.f, l.uv, l.t) for l in extra_lods]
    lo, hi = bounds(meshes[0][0]); radius = max(math.sqrt(sum(t * t for t in v)) for v in meshes[0][0])
    hdr = pack('fii', radius, 0, len(meshes)) + vec(lo) + vec(hi) + pack('i', len(meshes)) + pack('i' * len(meshes), *range(len(meshes))) + pack('i', 0)
    hdr += pack('f', 1e12) + vec((0, 0, 0)) + vec((.001, 0, 0)) + vec((0, .001, 0)) + vec((0, 0, .001)) + pack('ii', 0, 0)
    data = b'PSPO' + pack('i', 2117) + chunk('HDR2', hdr)
    for i, (vs, fs, uv, tid) in enumerate(meshes):
        tree = bsp(vs, fs, uv, tid)
        data += chunk('OBJ2', pack('ifi', i, radius, -1) + vec((0, 0, 0)) + vec((0, 0, 0)) + vec(lo) + vec(hi) + string(f'detail{i}') + string('') + pack('iii', 0, -1, 0) + pack('i', len(tree)) + tree)
    data += chunk('TXTR', pack('i', len(textures)) + b''.join(string(t) for t in textures))
    path.write_bytes(data)
    return dict(triangles=len(meshes[0][1]), radius=radius)

# ------------------------------------------------------------------ textures
def fbm2(shape, scale, octaves=5, seed=0):
    y, x = np.mgrid[0:shape[0], 0:shape[1]].astype(np.float32)
    out = np.zeros(shape, np.float32); a = 0.5
    for o in range(octaves):
        out += a * noise(x / scale * 2 ** o + seed, y / scale * 2 ** o - seed, np.full(shape, 0.37 * o + seed, np.float32)); a *= 0.5
    return out

def make_textures():
    S = 1024; maps = DATA / 'maps'
    g = fbm2((S, S), 160, 5, 3)
    # Concrete: large poured panels, seams, water streaks; windows in the glow map.
    conc = 0.50 + (g - 0.45) * 0.35
    yy, xx = np.mgrid[0:S, 0:S]
    seam = ((xx % 256) < 3) | ((yy % 128) < 3)
    streak = fbm2((S, S), 40, 3, 9) * np.clip((yy % 128) / 128.0, 0, 1)
    conc = conc - seam * 0.12 - streak * 0.10
    rgb = np.stack([conc * 1.02, conc * 1.0, conc * 0.95], -1)
    Image.fromarray(np.uint8(np.clip(rgb, 0, 1) * 255)).save(maps / 'ss_concrete.png')
    glow = np.zeros((S, S, 3), np.float32)
    win = ((yy % 128) > 52) & ((yy % 128) < 74) & ((xx % 64) > 10) & ((xx % 64) < 52)
    lit = (fbm2((S, S), 30, 2, 5) > 0.47)
    glow[win & lit] = (1.0, 0.82, 0.55); glow[win & ~lit] = (0.04, 0.05, 0.06)
    Image.fromarray(np.uint8(glow * 255)).save(maps / 'ss_concrete-glow.png')
    # Imperial metal: dark grey plating with panel lines and light strips.
    m = 0.30 + (fbm2((S, S), 90, 4, 21) - 0.45) * 0.18
    panel = ((xx % 128) < 2) | ((yy % 64) < 2) | (((xx // 128 + yy // 64) % 3 == 0) & ((xx % 128) < 64))
    m = m - panel * 0.06
    Image.fromarray(np.uint8(np.clip(np.stack([m, m * 1.01, m * 1.05], -1), 0, 1) * 255)).save(maps / 'ss_metal.png')
    mg = np.zeros((S, S, 3), np.float32)
    strip = ((yy % 256) > 120) & ((yy % 256) < 128) & ((xx % 32) < 22)
    mg[strip] = (0.55, 0.85, 1.0)
    Image.fromarray(np.uint8(mg * 255)).save(maps / 'ss_metal-glow.png')
    # Landing pad: dark tarmac, yellow ring and markings.
    pad = Image.fromarray(np.uint8(np.clip(np.stack([0.18 + g * 0.1] * 3, -1), 0, 1) * 255)); d = ImageDraw.Draw(pad)
    d.ellipse((112, 112, 912, 912), outline=(215, 170, 40), width=28)
    d.rectangle((300, 470, 724, 554), fill=(215, 170, 40)); d.rectangle((470, 300, 554, 724), fill=(215, 170, 40))
    pad.save(maps / 'ss_pad.png')
    pg = Image.new('RGB', (S, S)); d = ImageDraw.Draw(pg)
    for k in range(16):
        a = 2 * math.pi * k / 16; x, y = 512 + 430 * math.cos(a), 512 + 430 * math.sin(a); d.ellipse((x - 14, y - 14, x + 14, y + 14), fill=(255, 120, 60))
    pg.save(maps / 'ss_pad-glow.png')
    # Rock and trees.
    r = fbm2((512, 512), 60, 6, 13)
    Image.fromarray(np.uint8(np.clip(np.stack([0.20 + r * .22, 0.18 + r * .20, 0.16 + r * .17], -1), 0, 1) * 255)).save(maps / 'ss_rock.png')
    t = fbm2((256, 256), 12, 4, 17)
    Image.fromarray(np.uint8(np.clip(np.stack([0.06 + t * .10, 0.15 + t * .16, 0.06 + t * .08], -1), 0, 1) * 255)).save(maps / 'ss_needles.png')
    Image.fromarray(np.uint8(np.clip(np.stack([0.24 + t * .1, 0.17 + t * .08, 0.11 + t * .05], -1), 0, 1) * 255)).save(maps / 'ss_bark.png')

# ------------------------------------------------------------------ building assets (local frame: y up)
TEX = ['ss_concrete', 'ss_metal', 'ss_pad']
def building(kind):
    m = Mesh()
    plinth = lambda w, d, depth=14: m.box((0, -depth / 2, 0), (w + 2, depth, d + 2), 0)
    if kind == 'bunker':
        plinth(42, 26); m.box((0, 4, 0), (40, 8, 24), 0); m.box((0, 9, 0), (34, 2.5, 18), 1)
        m.box((0, 11.5, -4), (6, 3, 6), 1); m.cylinder((10, 10.2, 5), 1.2, 9, 1, 8)
    elif kind == 'hangar':
        plinth(42, 64); m.vault((0, 0, 0), 20, 60, 1); m.box((0, 2.5, 30.5), (34, 5, 1), 0)
    elif kind == 'barracks':
        plinth(66, 16); m.box((0, 5, 0), (64, 10, 14), 0); m.box((0, 10.6, 0), (60, 1.2, 10), 1)
        for k in range(4): m.box((-24 + 16 * k, 12.4, 0), (4, 2.4, 4), 1)
    elif kind == 'tower':
        plinth(14, 14)
        for sx in (-1, 1):
            for sz in (-1, 1): m.box((sx * 4, 28, sz * 4), (1.4, 56, 1.4), 1)
        for y in (14, 28, 42): m.box((0, y, 0), (10, 0.8, 10), 1)
        m.box((0, 57, 0), (11, 3, 11), 0); m.cylinder((0, 58.5, 0), 0.5, 18, 1, 6)
        m.cylinder((0, 61, 6), 5, 2.5, 1, 14, r2=0.5)
    elif kind == 'pad':
        m.box((0, -6, 0), (54, 12, 54), 0)
        oct_r = 26
        pts = [(oct_r * math.sin(2 * math.pi * k / 8 + math.pi / 8), oct_r * math.cos(2 * math.pi * k / 8 + math.pi / 8)) for k in range(8)]
        for k in range(8):
            a, b = pts[k], pts[(k + 1) % 8]
            m.tri((0, 0.6, 0), (a[0], 0.6, a[1]), (b[0], 0.6, b[1]), 2, [(0.5, 0.5), (0.5 + a[0] / 54, 0.5 - a[1] / 54), (0.5 + b[0] / 54, 0.5 - b[1] / 54)])
    elif kind == 'tanks':
        plinth(40, 16)
        for k in range(3): m.cylinder((-13 + 13 * k, 0, 0), 6, 15, 1, 18); m.cylinder((-13 + 13 * k, 15, 0), 6, 3, 1, 18, r2=2)
    elif kind == 'pylon':
        m.box((0, -6, 0), (18, 12, 18), 0); m.cylinder((0, 0, 0), 8, 30, 0, 10, r2=5.5, cap=False)
        m.box((0, 31, 0), (16, 2, 16), 1)
    elif kind == 'wall':
        m.box((0, -3, 0), (82, 18, 4), 0); m.box((0, 7, 0), (80, 2, 5), 1)
    return m

# ------------------------------------------------------------------ vegetation / rocks (per patch, world offsets)
def boulder(mesh, center, up, size, seed, subdiv=2):
    t = (1 + 5 ** 0.5) / 2
    V = [(-1, t, 0), (1, t, 0), (-1, -t, 0), (1, -t, 0), (0, -1, t), (0, 1, t), (0, -1, -t), (0, 1, -t), (t, 0, -1), (t, 0, 1), (-t, 0, -1), (-t, 0, 1)]
    F = [(0, 11, 5), (0, 5, 1), (0, 1, 7), (0, 7, 10), (0, 10, 11), (1, 5, 9), (5, 11, 4), (11, 10, 2), (10, 7, 6), (7, 1, 8), (3, 9, 4), (3, 4, 2), (3, 2, 6), (3, 6, 8), (3, 8, 9), (4, 9, 5), (2, 4, 11), (6, 2, 10), (8, 6, 7), (9, 8, 1)]
    V = [np.array(v) / np.linalg.norm(v) for v in V]
    for _ in range(subdiv):
        cache = {}; NF = []
        def mid(a, b):
            k = (min(a, b), max(a, b))
            if k not in cache: V.append((V[a] + V[b]) / np.linalg.norm(V[a] + V[b])); cache[k] = len(V) - 1
            return cache[k]
        for a, b, c in F:
            ab, bc, ca = mid(a, b), mid(b, c), mid(c, a); NF += [(a, ab, ca), (b, bc, ab), (c, ca, bc), (ab, bc, ca)]
        F = NF
    r_, _, f_ = frame(up, seed)
    squash = 0.55 + 0.3 * ((seed * 7.3) % 1)
    base = len(mesh.v)
    for v in V:
        n = 0.75 + 0.5 * noise(np.array(v[0] * 2.3 + seed), np.array(v[1] * 2.3), np.array(v[2] * 2.3 - seed))
        lv = v * size * n
        p = center + r_ * lv[0] + up * (lv[1] * squash + size * 0.25) + f_ * lv[2]
        mesh.v.append(tuple(p)); mesh.uv.append((float(v[0] + v[2]) * 0.5, float(v[1]) * 0.5))
    cw = center + up * size * 0.25
    for a, b, c in F:
        tri = (base + a, base + b, base + c)
        va, vb, vc = (np.array(mesh.v[i]) for i in tri)
        if np.dot(np.cross(vb - va, vc - va), (va + vb + vc) / 3 - cw) < 0: tri = (tri[0], tri[2], tri[1])
        mesh.f.append(tri); mesh.t.append(0)

def conifer(mesh, base_p, up, height, seed, simple=False):
    r_, _, f_ = frame(up, seed)
    def ring(y, rad, n):
        return [base_p + up * y + (r_ * math.sin(2 * math.pi * k / n) + f_ * math.cos(2 * math.pi * k / n)) * rad for k in range(n)]
    def frustum(y0, y1, r0, r1, n, tid):
        a, b = ring(y0, r0, n), ring(y1, r1, n)
        for k in range(n):
            k2 = (k + 1) % n; i = len(mesh.v)
            mesh.v += [tuple(a[k]), tuple(a[k2]), tuple(b[k2]), tuple(b[k])]; mesh.uv += [(k / n, 1), ((k + 1) / n, 1), ((k + 1) / n, 0), (k / n, 0)]
            axis = base_p + up * ((y0 + y1) / 2)
            for tri in [(i, i + 1, i + 2), (i, i + 2, i + 3)]:
                va, vb, vc = (np.array(mesh.v[j]) for j in tri)
                if np.dot(np.cross(vb - va, vc - va), (va + vb + vc) / 3 - axis) < 0: tri = (tri[0], tri[2], tri[1])
                mesh.f.append(tri); mesh.t.append(tid)
    if simple:
        frustum(height * 0.10, height, height * 0.27, 0.02, 5, 0); return
    frustum(-1.5, height * 0.3, height * 0.035, height * 0.025, 6, 1)
    for k, (y0, w) in enumerate([(0.22, 0.30), (0.45, 0.24), (0.66, 0.17)]):
        frustum(height * y0, height * (y0 + 0.36), height * w, 0.02, 9, 0)

# ------------------------------------------------------------------ layout
def main():
    make_textures()
    out = dict(prop_classes=[], props=[], ships=[])
    models = DATA / 'models'
    for old in models.glob('ss_g_*.pof'): old.unlink()
    for kind in ['bunker', 'hangar', 'barracks', 'tower', 'pad', 'tanks', 'pylon', 'wall']:
        info = write_pof(models / f'ss_g_{kind}.pof', building(kind), TEX, [EMPTY])
        out['prop_classes'].append(dict(name=f'SpaceSim {kind.title()}', pof=f'ss_g_{kind}.pof', detail=[0, 9000]))
    def place_prop(name, kind, x, z, heading, sink=1.0):
        p, up, h = surface(x, z)
        r, u, f = frame(up, heading)
        out['props'].append(dict(name=name, cls=f'SpaceSim {kind.title()}', pos=list(p - up * sink - CENTER * 0 + 0), orient=[list(r), list(u), list(f)]))
        return p, up
    def place_ship(name, cls, x, z, heading, lift, team='Hostile', on=None):
        if on is None: p, up, _ = surface(x, z)
        else: p, up = on
        r, u, f = frame(up, heading)
        out['ships'].append(dict(name=name, cls=cls, team=team, pos=list(p + up * lift), orient=[list(r), list(u), list(f)]))
    reserved = []
    # Imperial outpost on the valley floor ahead of the start, under the auto-flight path.
    zc = -1200.0; xc = valley_x(zc)
    layout = [('hangar', -70, 40, 0.0), ('hangar', 70, 40, 0.0), ('barracks', -95, -70, 1.57), ('barracks', 95, -70, 1.57),
              ('bunker', 0, -130, 0.0), ('tower', 150, -10, 0.3), ('tanks', -150, -10, 0.0), ('pad', 0, 150, 0.0),
              ('pad', -150, 160, 0.0), ('wall', 0, -220, 0.0), ('wall', -90, -220, 0.0), ('wall', 90, -220, 0.0),
              ('bunker', 230, 120, 0.4), ('barracks', -230, 110, 1.2)]
    # Destructible buildings are real ships: on radar, targetable, destroyed by actual weapon damage.
    TARGETS = {'bunker': 'Bunker imperial', 'hangar': 'Hangar imperial', 'barracks': 'Caserne imperiale',
               'tower': 'Tour de communication', 'tanks': 'Reservoirs imperiaux'}
    for k, (kind, dx, dz, hd) in enumerate(layout):
        if kind in TARGETS:
            p_, up_, _ = surface(xc + dx, zc + dz)
            place_ship(f'{TARGETS[kind]} {k}', TARGETS[kind], xc + dx, zc + dz, hd, -0.8, on=(p_, up_))
        else:
            place_prop(f'Base {kind} {k}', kind, xc + dx, zc + dz, hd, sink=0.8)
        reserved.append((xc + dx, zc + dz, 70))
    # Ship classes for the destructible buildings (modular table, FotG container template).
    HP = {'bunker': 1400, 'hangar': 1800, 'barracks': 1200, 'tower': 700, 'tanks': 650}
    tbl = ['#Ship Classes', '']
    for kind, name in TARGETS.items():
        tbl += [f'$Name: {name}', '  +Use Template: TN-series #Container Template', f'  $Display Name: {name}', '  $Species: Imperial',
                f'  $POF file: ss_g_{kind}.pof', '  $POF target LOD: 0', '  $Detail distance: (0, 9000)', '  $Collision LOD: 0',
                f'  $Hitpoints: {HP[kind]}',
                '  $Flags: ( "cruiser" "large ship deathroll" "no ets" "intrinsic no shields" "disable all generic impact debris" "disable all generic explosion debris" )',
                '  $Closeup_pos: 0.0, 10.0, -120', '  $Closeup_pos_targetbox: 0.0, 10.0, -120', '']
    tbl.append('#End')
    (DATA / 'tables/spacesim-shp.tbm').write_text('\n'.join(tbl) + '\n')
    p, up = place_prop('Base pad lambda', 'pad', xc + 150, zc + 160, 0.0, 0.0) if False else (None, None)
    pp, upp, _ = surface(xc, zc + 150)
    place_ship('Lambda Ombre', 'Lambda T-4a Shuttle', xc, zc + 150, 2.6, 15.9, team='Hostile', on=(pp + upp * 0.6, upp))
    pp, upp, _ = surface(xc - 150, zc + 160)
    place_ship('Cargo 1', 'BFF-1 Container', xc - 150, zc + 160, 0.4, 8.3, on=(pp + upp * 0.6, upp))
    for k, (dx, dz, hd) in enumerate([(-40, 260, 0.2), (55, 330, -0.5), (-20, -330, 3.0)]):
        place_ship(f'AT-AT {k+1}', 'AT-AT#Static', xc + dx, zc + dz, hd, 18.0)
    # Turbolaser towers (pylon + Imperial defense battery) on both shoulders of the valley, along the route.
    tower = 0
    for z in (-3600, -2200, -700, 900, 2600):
        for side in (-1, 1):
            off = 720 + 60 * ((z // 100) % 3)
            x = valley_x(z) + side * off
            pp, upp = place_prop(f'Pylone {tower}', 'pylon', x, z, 0.0, sink=0.5)
            place_ship(f'Batterie {tower+1}', 'Defense Satellite#Imp', x, z, 0.0, 0.0, on=(pp + upp * (32.5 + 27.0), upp))
            reserved.append((x, z, 40)); tower += 1
    for k, z in enumerate(range(-4600, 4000, 900)):
        for side in (-1, 1):
            place_ship(f'Balise {k}{"G" if side < 0 else "D"}', 'Nav Buoy#real', valley_x(z) + side * 330, z, 0.0, 2.3, team='Friendly')
    # Boulder fields and conifer forests, each one unique POF following the terrain.
    def free(x, z, rad):
        return all((x - a) ** 2 + (z - b) ** 2 > (rad + c) ** 2 for a, b, c in reserved)
    rocks = forests = 0
    for k in range(130):
        z = float(rng.uniform(-6500, 6500)); side = rng.choice([-1, 1]); x = valley_x(z) + side * float(rng.uniform(150, 1400))
        if not free(x, z, 160): continue
        p0, up0, h0 = surface(x, z); sl, _ = slope_at(x, z)
        is_forest = h0 < 1650 and sl < 0.42 and k % 4 != 0
        m = Mesh(); m1 = Mesh()
        n_items = 170 if is_forest else 38
        for i in range(n_items):
            a = rng.uniform(0, 2 * math.pi); rr = 140 * math.sqrt(rng.uniform(0, 1))
            xi, zi = x + rr * math.cos(a), z + rr * math.sin(a)
            pi, upi, hi = surface(xi, zi)
            if is_forest:
                s2, _ = slope_at(xi, zi, 4)
                if hi > 1800 or s2 > 0.55: continue
                hgt, sd = float(rng.uniform(9, 26)), float(rng.uniform(0, 6.28))
                conifer(m, pi - p0, upi, hgt, sd)
                if i % 2 == 0: conifer(m1, pi - p0, upi, hgt * 1.05, sd, simple=True)
            else:
                size, sd = float(rng.uniform(1.5, 11) if rng.uniform() < 0.85 else rng.uniform(12, 24)), float(rng.uniform(0, 6.28))
                boulder(m, pi - p0, upi, size, sd)
                if size > 4: boulder(m1, pi - p0, upi, size, sd, subdiv=1)
        if not m.f: continue
        name = f'ss_g_{"forest" if is_forest else "rocks"}{k:02d}'
        info = write_pof(models / f'{name}.pof', m, ['ss_needles', 'ss_bark'] if is_forest else ['ss_rock'], [m1 if m1.f else EMPTY, EMPTY])
        cls = f'SpaceSim {name[5:].title()}'
        out['prop_classes'].append(dict(name=cls, pof=f'{name}.pof', detail=[0, 1400, 6500] if is_forest else [0, 1600, 8000]))
        out['props'].append(dict(name=f'Nature {name[5:]}', cls=cls, pos=list(p0), orient=[[1, 0, 0], [0, 1, 0], [0, 0, 1]]))
        reserved.append((x, z, 140))
        forests += is_forest; rocks += not is_forest
    for p in out['props']: p['pos'] = [float(c) for c in p['pos']]; p['orient'] = [[float(c) for c in r] for r in p['orient']]
    for s in out['ships']: s['pos'] = [float(c) for c in s['pos']]; s['orient'] = [[float(c) for c in r] for r in s['orient']]
    (ROOT / 'artifacts/planet/ground.json').write_text(json.dumps(out, indent=1))
    print(f"Ground: {len(out['props'])} props ({forests} forests, {rocks} rock fields), {len(out['ships'])} ships, outpost at z={zc:.0f}")

if __name__ == '__main__':
    main()
