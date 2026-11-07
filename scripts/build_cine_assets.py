"""Assets for the Aurore evasion cinematic: molten planetary core and particle glow sprites."""
import math
import numpy as np
from PIL import Image, ImageFilter
from build_planet import DATA, noise
from build_terrain import pack, vec, string, chunk, bsp, bounds

def core_model(radius=76000.0, nlon=160, nlat=80):
    verts, uvs, faces = [], [], []
    for j in range(nlat + 1):
        lat = (-math.pi / 2 + math.pi * j / nlat) * 0.995
        for i in range(nlon + 1):
            lon = 2 * math.pi * i / nlon
            d = (math.cos(lat) * math.sin(lon), math.sin(lat), math.cos(lat) * math.cos(lon))
            verts.append(tuple(c * radius for c in d)); uvs.append((i / nlon, 1 - j / nlat))
    w = nlon + 1
    for j in range(nlat):
        for i in range(nlon):
            a, b, c, e = j * w + i, j * w + i + 1, (j + 1) * w + i, (j + 1) * w + i + 1
            pa, pb, pc = (np.array(verts[k]) for k in (a, b, c))
            if np.dot(np.cross(pb - pa, pc - pa), pa) > 0: faces += [(a, b, c), (b, e, c)]
            else: faces += [(a, c, b), (b, c, e)]
    lo, hi = bounds(verts); rad = radius
    tree = bsp(verts, faces, uvs)
    hdr = pack('fii', rad, 0, 1) + vec(lo) + vec(hi) + pack('iii', 1, 0, 0)
    hdr += pack('f', 1e12) + vec((0, 0, 0)) + vec((.001, 0, 0)) + vec((0, .001, 0)) + vec((0, 0, .001)) + pack('ii', 0, 0)
    obj = pack('ifi', 0, rad, -1) + vec((0, 0, 0)) + vec((0, 0, 0)) + vec(lo) + vec(hi) + string('detail0') + string('') + pack('iii', 0, -1, 0) + pack('i', len(tree)) + tree
    (DATA / 'models/ss_core.pof').write_bytes(b'PSPO' + pack('i', 2117) + chunk('HDR2', hdr) + chunk('OBJ2', obj) + chunk('TXTR', pack('i', 1) + string('ss_core')))

def lava_textures(W=2048, H=1024):
    y, x = np.mgrid[0:H, 0:W].astype(np.float32)
    lon = x / W * 2 * math.pi; lat = (y / H - 0.5) * math.pi
    d = [np.cos(lat) * np.sin(lon), np.sin(lat), np.cos(lat) * np.cos(lon)]
    n = np.zeros((H, W), np.float32); a = 0.5; f = 3.0
    for o in range(6):
        n += a * noise(d[0] * f + 7.1 * o, d[1] * f, d[2] * f - 3.3 * o); a *= 0.5; f *= 2.1
    veins = 1 - np.abs(2 * n - 1)                      # bright molten rivers between dark crust plates
    heat = np.clip((veins - 0.55) * 3.5, 0, 1)
    crust = np.stack([0.10 + 0.05 * n, 0.04 + 0.02 * n, 0.02 + 0.01 * n], -1)
    molten = np.stack([np.ones_like(n), 0.35 + 0.45 * heat, 0.05 + 0.15 * heat ** 3], -1)
    alb = crust * (1 - heat[..., None]) + molten * heat[..., None]
    Image.fromarray(np.uint8(np.clip(alb, 0, 1) * 255)).save(DATA / 'maps/ss_core.png')
    glow = molten * (0.25 + heat[..., None] * 0.95)
    Image.fromarray(np.uint8(np.clip(glow, 0, 1) * 255)).save(DATA / 'maps/ss_core-glow.png')

def sprites():
    S = 256; y, x = np.mgrid[0:S, 0:S].astype(np.float32)
    r = np.hypot(x - S / 2 + 0.5, y - S / 2 + 0.5) / (S / 2)
    g = np.clip(1 - r, 0, 1) ** 2.2
    Image.fromarray(np.uint8(np.stack([g, g, g], -1) * 255)).save(DATA / 'maps/ss_glow.png')
    ring = np.exp(-((r - 0.78) / 0.10) ** 2) + 0.35 * g
    Image.fromarray(np.uint8(np.clip(np.stack([ring, ring, ring], -1), 0, 1) * 255)).save(DATA / 'maps/ss_ringglow.png')


def fragments():
    """Irregular planetary chunks (jagged, flattened, glowing fracture veins). 3 sizes x 4 shapes."""
    t = (1 + 5 ** 0.5) / 2
    V0 = np.array([(-1, t, 0), (1, t, 0), (-1, -t, 0), (1, -t, 0), (0, -1, t), (0, 1, t), (0, -1, -t), (0, 1, -t), (t, 0, -1), (t, 0, 1), (-t, 0, -1), (-t, 0, 1)], float)
    F0 = [(0, 11, 5), (0, 5, 1), (0, 1, 7), (0, 7, 10), (0, 10, 11), (1, 5, 9), (5, 11, 4), (11, 10, 2), (10, 7, 6), (7, 1, 8), (3, 9, 4), (3, 4, 2), (3, 2, 6), (3, 6, 8), (3, 8, 9), (4, 9, 5), (2, 4, 11), (6, 2, 10), (8, 6, 7), (9, 8, 1)]
    names = []
    for si, size in enumerate((9000.0, 4500.0, 2000.0)):
        for shape in range(4):
            V = [v / np.linalg.norm(v) for v in V0]; F = list(F0)
            for _ in range(2):
                cache = {}; NF = []
                def mid(a, b):
                    k = (min(a, b), max(a, b))
                    if k not in cache: m = V[a] + V[b]; V.append(m / np.linalg.norm(m)); cache[k] = len(V) - 1
                    return cache[k]
                for a, b, c in F:
                    ab, bc, ca = mid(a, b), mid(b, c), mid(c, a); NF += [(a, ab, ca), (b, bc, ab), (c, ca, bc), (ab, bc, ca)]
                F = NF
            rng = np.random.default_rng(si * 10 + shape)
            axes = rng.uniform(0.45, 1.25, 3)
            verts = []
            for v in V:
                n = noise(np.array(v[0] * 1.7 + shape * 3.1), np.array(v[1] * 1.7), np.array(v[2] * 1.7 - shape))
                n2 = noise(np.array(v[0] * 5.3 + shape), np.array(v[1] * 5.3 + 2.0), np.array(v[2] * 5.3))
                r = size * (0.55 + 0.55 * float(n) + 0.18 * float(n2))
                verts.append(tuple(float(c) for c in v * axes * r))
            faces = []
            for a, b, c in F:
                pa, pb, pc = (np.array(verts[k]) for k in (a, b, c))
                faces.append((a, b, c) if np.dot(np.cross(pb - pa, pc - pa), pa + pb + pc) > 0 else (a, c, b))
            uvs = [(float(v[0] * 0.5 + 0.5), float(v[1] * 0.5 + 0.5)) for v in V]
            lo, hi = bounds(verts); rad = max(math.sqrt(sum(x * x for x in v)) for v in verts)
            tree = bsp(verts, faces, uvs)
            hdr = pack('fii', rad, 0, 1) + vec(lo) + vec(hi) + pack('iii', 1, 0, 0)
            hdr += pack('f', 1e12) + vec((0, 0, 0)) + vec((.001, 0, 0)) + vec((0, .001, 0)) + vec((0, 0, .001)) + pack('ii', 0, 0)
            obj = pack('ifi', 0, rad, -1) + vec((0, 0, 0)) + vec((0, 0, 0)) + vec(lo) + vec(hi) + string('detail0') + string('') + pack('iii', 0, -1, 0) + pack('i', len(tree)) + tree
            name = f'ss_frag{si}{shape}'
            (DATA / 'models' / f'{name}.pof').write_bytes(b'PSPO' + pack('i', 2117) + chunk('HDR2', hdr) + chunk('OBJ2', obj) + chunk('TXTR', pack('i', 1) + string('ss_frag')))
            names.append(name)
    # crust with molten fracture veins (glow map makes the cracks burn)
    W = 1024; y, x = np.mgrid[0:W, 0:W].astype(np.float32) / W
    n = np.zeros((W, W), np.float32); a = 0.5; f = 4.0
    for o in range(5):
        n += a * noise(x * f + o * 3.3, y * f - o, np.full_like(x, o * 0.7)); a *= 0.5; f *= 2.0
    vein = np.clip((1 - np.abs(2 * n - 1) - 0.82) * 6, 0, 1)
    crust = np.stack([0.22 + 0.10 * n, 0.18 + 0.08 * n, 0.15 + 0.06 * n], -1)
    alb = crust * (1 - vein[..., None]) + np.array([1.0, 0.45, 0.08]) * vein[..., None]
    Image.fromarray(np.uint8(np.clip(alb, 0, 1) * 255)).save(DATA / 'maps/ss_frag.png')
    glow = np.array([1.0, 0.42, 0.06]) * vein[..., None] * 1.0
    Image.fromarray(np.uint8(np.clip(glow, 0, 1) * 255)).save(DATA / 'maps/ss_frag-glow.png')
    return names

def tinted_sprites():
    S = 256; y, x = np.mgrid[0:S, 0:S].astype(np.float32)
    r = np.hypot(x - S / 2 + 0.5, y - S / 2 + 0.5) / (S / 2)
    g = np.clip(1 - r, 0, 1) ** 2.0
    for name, col in [('ss_glow_orange', (1.0, 0.55, 0.15)), ('ss_glow_blue', (0.65, 0.82, 1.0)), ('ss_glow_white', (1.0, 0.97, 0.9))]:
        Image.fromarray(np.uint8(np.clip(np.stack([g * col[0], g * col[1], g * col[2]], -1), 0, 1) * 255)).save(DATA / f'maps/{name}.png')

if __name__ == '__main__':
    lava_textures(); core_model(); sprites(); tinted_sprites(); print('fragments', len(fragments()))
    print('Cinematic assets: core (76 km), lava maps, glow sprites')
