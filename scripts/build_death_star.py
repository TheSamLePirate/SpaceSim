"""Procedural Death Star for the Aurore evasion cinematic (original geometry, no external asset).

Sphere of 15 km radius (30 km diameter: massive, yet clearly smaller than the 160 km planet),
equatorial trench, concave superlaser dish in the northern hemisphere with its focusing lens,
lat-long textures: hull plating, sectors, trenches, and thousands of lights (glow map) that read
on the night side. Split into sub-objects to respect the 65 535-vertex limit.
"""
from pathlib import Path
import math
import numpy as np
from PIL import Image, ImageDraw, ImageFilter
from build_planet import DATA, ROOT
from build_terrain import pack, vec, string, chunk, bsp, bounds

RDS = 15000.0
DISH_LAT, DISH_LON = math.radians(32.0), math.radians(0.0)
DISH_ANG = 0.30          # angular radius of the dish (rad)
TRENCH_W = 0.012         # angular half width of the equatorial trench (rad)

def dish_dir():
    return np.array([math.cos(DISH_LAT) * math.sin(DISH_LON), math.sin(DISH_LAT), math.cos(DISH_LAT) * math.cos(DISH_LON)])

def radius_at(d):
    """d: (...,3) unit directions -> surface radius."""
    lat = np.arcsin(np.clip(d[..., 1], -1, 1))
    r = np.full(d.shape[:-1], RDS)
    trench = np.clip(1 - np.abs(lat) / TRENCH_W, 0, 1)
    r -= 380.0 * (trench > 0) * np.minimum(1, trench * 4)                      # square-ish trench
    ang = np.arccos(np.clip(d @ dish_dir(), -1, 1))
    x = np.clip(ang / DISH_ANG, 0, 1.2)
    dish = np.where(x < 1, 0.085 * RDS * (1 - x * x), 0)                        # concave bowl
    rim = 120.0 * np.exp(-((x - 1.0) / 0.035) ** 2)                             # raised rim
    lens = np.where(x < 0.11, 0.035 * RDS * (1 - (x / 0.11) ** 2), 0)           # focusing lens at the centre
    return r - dish + rim + lens

def build_mesh(nlon=640, nlat=360):
    # latitude rings denser near the trench and the dish band
    t = np.linspace(-1, 1, nlat + 1)
    lat = np.sign(t) * (np.abs(t) ** 1.25) * (math.pi / 2 - 1e-4)
    lon = np.linspace(-math.pi, math.pi, nlon + 1)
    LON, LAT = np.meshgrid(lon, lat)
    d = np.stack([np.cos(LAT) * np.sin(LON), np.sin(LAT), np.cos(LAT) * np.cos(LON)], -1)
    P = d * radius_at(d)[..., None]
    U = (LON + math.pi) / (2 * math.pi); V = 1 - (LAT + math.pi / 2) / math.pi
    groups = []
    rows_per = max(1, 60000 // (nlon + 1) - 1)
    for r0 in range(0, nlat, rows_per):
        r1 = min(nlat, r0 + rows_per)
        verts, uvs, faces = [], [], []
        for j in range(r0, r1 + 1):
            for i in range(nlon + 1):
                verts.append(tuple(P[j, i])); uvs.append((float(U[j, i]), float(V[j, i])))
        w = nlon + 1
        for j in range(r1 - r0):
            for i in range(nlon):
                a, b, c, e = j * w + i, j * w + i + 1, (j + 1) * w + i, (j + 1) * w + i + 1
                pa, pb, pc = np.array(verts[a]), np.array(verts[b]), np.array(verts[c])
                n = np.cross(pb - pa, pc - pa)
                if np.dot(n, pa) > 0: faces += [(a, b, c), (b, e, c)]
                else: faces += [(a, c, b), (b, c, e)]
        groups.append((verts, faces, uvs, [0] * len(faces)))
    return groups

def textures(W=4096, H=2048):
    rng = np.random.default_rng(3)
    y, x = np.mgrid[0:H, 0:W].astype(np.float32)
    lon = x / W * 2 * math.pi - math.pi; lat = (1 - y / H) * math.pi - math.pi / 2
    base = 0.46 + 0.05 * rng.standard_normal((H, W)).astype(np.float32) * 0.3
    # plating at three scales (scaled in longitude by cos(lat) to keep panels square-ish)
    cl = np.maximum(np.cos(lat), 0.08)
    def grid(nx, ny, w):
        gx = (lon * cl * nx / (2 * math.pi)) % 1.0; gy = (lat * ny / math.pi) % 1.0
        return ((gx < w) | (gy < w * 1.2)).astype(np.float32)
    img = base - 0.05 * grid(360, 180, 0.04) - 0.035 * grid(1440, 720, 0.07)
    # sectors: blocks of slightly different tone and surface "cities"
    sx = np.floor(lon * cl * 48 / (2 * math.pi)); sy = np.floor(lat * 24 / math.pi)
    tone = (np.sin(sx * 12.9898 + sy * 78.233) * 43758.5453) % 1.0
    img += (tone - 0.5) * 0.08
    city = ((np.sin(np.floor(lon * cl * 720) * 3.1 + np.floor(lat * 360) * 7.7) * 9131.3) % 1.0) > 0.86
    img -= city * 0.07
    # meridian & latitude service trenches
    trenches = (np.abs(np.sin(lon * 6)) < 0.004) | (np.abs(np.sin(lat * 8)) < 0.003)
    img -= trenches * 0.12
    eq = np.abs(lat) < TRENCH_W
    img = np.where(eq, img * 0.55, img)
    # dish: concentric rings, darker bowl
    d = np.stack([np.cos(lat) * np.sin(lon), np.sin(lat), np.cos(lat) * np.cos(lon)], -1)
    ang = np.arccos(np.clip(d @ dish_dir(), -1, 1)); xr = ang / DISH_ANG
    rings = (np.abs(np.sin(xr * 70)) < 0.18) & (xr < 1)
    img = np.where(xr < 1, img * 0.72 - rings * 0.06, img)
    alb = np.clip(np.stack([img, img * 1.01, img * 1.04], -1), 0, 1)
    Image.fromarray(np.uint8(alb * 255)).save(DATA / 'maps/ss_ds.png', compress_level=4)
    # glow: windows / beacons, trench lighting, superlaser tributaries
    glow = np.zeros((H, W, 3), np.float32)
    n = 60000
    gx = rng.integers(0, W, n); gy = rng.integers(0, H, n)
    col = np.where(rng.random(n)[:, None] < 0.85, [1.0, 0.86, 0.62], [0.65, 0.8, 1.0])
    glow[gy, gx] = col * rng.uniform(0.4, 1.0, n)[:, None]
    tr = eq & ((x.astype(int) % 7) < 2)
    glow[tr] = [1.0, 0.9, 0.7]
    trib = (xr > 0.55) & (xr < 0.62)
    ang8 = np.arctan2(*(np.stack([d @ np.array([1.0, 0, 0]), d @ np.cross(dish_dir(), [1.0, 0, 0])], -1)).transpose(2, 0, 1))
    emit = trib & (np.abs(((ang8 / (2 * math.pi) * 8) % 1.0) - 0.5) < 0.06)
    glow[emit] = [0.35, 1.0, 0.45]
    glow[(xr < 0.10)] = [0.12, 0.35, 0.16]
    gimg = Image.fromarray(np.uint8(np.clip(glow, 0, 1) * 255)).filter(ImageFilter.GaussianBlur(0.6))
    gimg.save(DATA / 'maps/ss_ds-glow.png', compress_level=4)
    shine = np.full((H, W, 3), 0.18, np.float32); shine[eq] = 0.08
    Image.fromarray(np.uint8(shine * 255)).save(DATA / 'maps/ss_ds-shine.png', compress_level=6)
    Image.fromarray(np.uint8(alb * 255)).resize((1024, 512)).save(ROOT / 'artifacts/planet/death-star-preview.jpg', quality=90)

def write_pof(path, groups, lods_far):
    subs = []
    root = 0
    for k, g in enumerate(groups):
        subs.append((k, -1 if k == 0 else 0, g, 'detail0' if k == 0 else f'detail0-{k}'))
    lod1 = len(subs); subs.append((lod1, -1, lods_far, 'detail1'))
    allv = [v for _, _, g, _ in subs for v in g[0]]
    lo, hi = bounds(allv); radius = max(math.sqrt(sum(t * t for t in v)) for v in allv)
    hdr = pack('fii', radius, 0, len(subs)) + vec(lo) + vec(hi) + pack('i', 2) + pack('ii', 0, lod1) + pack('i', 0)
    hdr += pack('f', 1e12) + vec((0, 0, 0)) + vec((.001, 0, 0)) + vec((0, .001, 0)) + vec((0, 0, .001)) + pack('ii', 0, 0)
    data = b'PSPO' + pack('i', 2117) + chunk('HDR2', hdr)
    for idx, parent, (vs, fs, uv, tid), name in subs:
        slo, shi = bounds(vs); srad = max(math.sqrt(sum(t * t for t in v)) for v in vs)
        tree = bsp(vs, fs, uv, tid)
        data += chunk('OBJ2', pack('ifi', idx, srad, parent) + vec((0, 0, 0)) + vec((0, 0, 0)) + vec(slo) + vec(shi) + string(name) + string('') + pack('iii', 0, -1, 0) + pack('i', len(tree)) + tree)
    data += chunk('TXTR', pack('i', 1) + string('ss_ds'))
    path.write_bytes(data)

def main():
    textures()
    near = build_mesh(640, 360)
    far = build_mesh(160, 90)
    fv, ff, fu, ft = [], [], [], []
    for vs, fs, uv, tid in far:
        o = len(fv); fv += vs; fu += uv; ft += tid; ff += [(a + o, b + o, c + o) for a, b, c in fs]
    write_pof(DATA / 'models/ss_deathstar.pof', near, (fv, ff, fu, ft))
    print(f'Death Star: radius {RDS/1000:.0f} km, {sum(len(g[1]) for g in near):,} tris near, {len(ff):,} far, {len(near)} sub-objects')

if __name__ == '__main__':
    main()
