"""Aurore: ground height map for the Lua scripts (flight model, ground warning, AI terrain avoidance).

It reproduces the COLLISION MESH, not the analytic relief: the same quadtree as build_planet_tiles
(read from artifacts/planet/tiles.json: depth and cells of the current build), the same vertex
heights, the same triangle split; heights are interpolated on those triangles. Coordinates: gnomonic projection on the planet's north face,
    a = R * d.x / d.y,  b = R * d.z / d.y      with d = unit(p - C), C = (0, -R, 0)
(a, b are metres along the surface near the landing site). Two grids:
    fine   : a in [-8, 8] km, b in [-13, 11] km, 12.5 m   (canyon, outpost, camp)
    coarse : a, b in [-60, 60] km, 200 m                  (the rest of the visible face)
Each height is 2 printable characters (base 94, ASCII 33..126): fine 0.5 m steps (0..4417 m),
coarse 2 m steps (0..17671 m). The Lua side decodes on demand (no big table in memory).
Output: mods/planet/data/spacesim-height.txt
Usage: build_planet_heightmap.py
"""
import json, sys, time
import numpy as np
from build_planet import R, DATA, ROOT, FACES, directions
import build_planet_tiles as BT

GRIDS = [  # name, a0, b0, step, na, nb, metres per unit
    ('fine', -8000.0, -13000.0, 12.5, 1281, 1921, 0.5),
    ('coarse', -60000.0, -60000.0, 200.0, 601, 601, 2.0),
]

def encode(h, unit):
    q = np.clip(np.round(h / unit), 0, 94 * 94 - 1).astype(np.int64)
    hi, lo = q // 94 + 33, q % 94 + 33
    out = np.empty(q.size * 2, np.uint8)
    out[0::2], out[1::2] = hi.ravel(), lo.ravel()
    return out.tobytes().decode('ascii')

def leaves():
    """North-face leaf tiles of the current build (same subdivision rule as build_planet_tiles)."""
    built = json.loads((ROOT / 'artifacts/planet/tiles.json').read_text())
    BT.DEPTH = max(t['depth'] for t in built)
    cells = round(built[0]['extent_m'] / built[0]['grid_m'])
    tiles = [t for t in BT.quadtree() if t[0][0] == 'north']
    assert len(tiles) == sum(1 for t in built if t['face'] == 'north'), 'tiles.json does not match the quadtree'
    return tiles, cells

def mesh_height(U, V, tiles, n):
    """Height of the LOD0 collision mesh at face coordinates (U, V) (same triangles as tile_mesh)."""
    H = np.full(U.shape, np.nan)
    for face, u0, v0, size, depth in tiles:
        m = (U >= u0) & (U < u0 + size) & (V >= v0) & (V < v0 + size)
        if not m.any(): continue
        ax = np.linspace(0, 1, n + 1)
        gu, gv = np.meshgrid(u0 + ax * size, v0 + ax * size)          # [j, i]
        hv = BT.elevation(directions(face, gu, gv))
        fu = (U[m] - u0) / size * n; fv = (V[m] - v0) / size * n
        i = np.clip(np.floor(fu).astype(int), 0, n - 1); j = np.clip(np.floor(fv).astype(int), 0, n - 1)
        tx, ty = fu - i, fv - j
        ha, hb, hc, he = hv[j, i], hv[j, i + 1], hv[j + 1, i], hv[j + 1, i + 1]
        low = tx + ty <= 1                                              # triangle (a, b, c), else (b, c, e)
        H[m] = np.where(low, ha + (hb - ha) * tx + (hc - ha) * ty, he + (hc - he) * (1 - tx) + (hb - he) * (1 - ty))
    return H

def main():
    t = time.time()
    tiles, cells = leaves()
    print(f'{len(tiles)} north tiles, depth {BT.DEPTH}, {cells} cells')
    lines = ['SPACESIM_HEIGHT 2']
    body = []
    for name, a0, b0, step, na, nb, unit in GRIDS:
        a = a0 + np.arange(na) * step
        b = b0 + np.arange(nb) * step
        A, B = np.meshgrid(a, b)                       # rows = b, cols = a
        h = mesh_height(A / R, B / R, tiles, cells)
        assert not np.isnan(h).any()
        lines.append(f'{name} {a0} {b0} {step} {na} {nb} {unit}')
        body.append(encode(h, unit))
        print(f'{name}: {na}x{nb}, h {h.min():.0f}..{h.max():.0f} m')
    out = DATA / 'spacesim-height.txt'
    out.write_text('\n'.join(lines + body) + '\n')
    print(f'{out} {out.stat().st_size / 1e6:.1f} MB in {time.time() - t:.0f} s')

if __name__ == '__main__':
    main()
