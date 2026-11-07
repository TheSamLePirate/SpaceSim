"""Tileable 128^3 cloud noise volume, packed as 16x8 padded slices in one RGBA PNG.

R: Perlin-Worley (base cloud shape)      G: Worley fbm, 2x frequency (erosion)
B: Worley fbm, 4x frequency (fine detail) A: Perlin fbm (weather / coverage)
Each slice is 130x130: a one-texel wrapped border lets the shader use hardware
bilinear filtering inside a slice, and it blends two slices for the third axis.
The image is attached as the '-misc' map of the terrain and sky materials.
"""
from pathlib import Path
import numpy as np
from PIL import Image
ROOT=Path(__file__).resolve().parent.parent
MAPS=ROOT/'mods/planet/data/maps'
N=128;TILE=N+2;COLS=16;ROWS=8
rng=np.random.default_rng(1977)
g=(np.arange(N,dtype=np.float32)+0.5)/N
X,Y,Z=np.meshgrid(g,g,g,indexing='ij')

def worley(cells):
    pts=rng.random((cells,cells,cells,3),dtype=np.float32)
    cx,cy,cz=[np.floor(a*cells).astype(np.int32) for a in (X,Y,Z)]
    best=np.full(X.shape,9.0,np.float32)
    for ox in (-1,0,1):
        for oy in (-1,0,1):
            for oz in (-1,0,1):
                ix,iy,iz=(cx+ox)%cells,(cy+oy)%cells,(cz+oz)%cells
                p=pts[ix,iy,iz]
                dx=(cx+ox+p[...,0])/cells-X;dy=(cy+oy+p[...,1])/cells-Y;dz=(cz+oz+p[...,2])/cells-Z
                best=np.minimum(best,dx*dx+dy*dy+dz*dz)
    return 1.0-np.clip(np.sqrt(best)*cells,0,1)   # inverted: 1 at feature points

def perlin(period):
    grads=rng.normal(size=(period,period,period,3)).astype(np.float32)
    grads/=np.linalg.norm(grads,axis=-1,keepdims=True)
    px,py,pz=X*period,Y*period,Z*period
    ix,iy,iz=np.floor(px).astype(np.int32),np.floor(py).astype(np.int32),np.floor(pz).astype(np.int32)
    fx,fy,fz=px-ix,py-iy,pz-iz
    fade=lambda t:t*t*t*(t*(t*6-15)+10)
    u,v,w=fade(fx),fade(fy),fade(fz)
    def corner(a,b,c):
        gr=grads[(ix+a)%period,(iy+b)%period,(iz+c)%period]
        return gr[...,0]*(fx-a)+gr[...,1]*(fy-b)+gr[...,2]*(fz-c)
    lerp=lambda a,b,t:a+(b-a)*t
    x00=lerp(corner(0,0,0),corner(1,0,0),u);x10=lerp(corner(0,1,0),corner(1,1,0),u)
    x01=lerp(corner(0,0,1),corner(1,0,1),u);x11=lerp(corner(0,1,1),corner(1,1,1),u)
    return lerp(lerp(x00,x10,v),lerp(x01,x11,v),w)*0.5+0.5

def fbm(fn,base,octaves,gain=0.5):
    total=np.zeros(X.shape,np.float32);amp=1.0;norm=0.0
    for o in range(octaves):
        total+=amp*fn(base*2**o);norm+=amp;amp*=gain
    return total/norm

def remap(v,a,b,c,d): return c+(v-a)/(b-a)*(d-c)

def main():
    print('Perlin...',flush=True)
    pfbm=fbm(perlin,4,5)
    pfbm=np.clip((pfbm-pfbm.min())/(pfbm.max()-pfbm.min()),0,1)
    print('Worley...',flush=True)
    w4,w8,w16,w32,w64=[worley(c) for c in (4,8,16,32,64)]
    wfbm_low=w4*0.625+w8*0.25+w16*0.125
    R=np.clip(remap(pfbm,wfbm_low-1.0,1.0,0.0,1.0),0,1)          # Perlin-Worley
    G=w8*0.625+w16*0.25+w32*0.125
    B=w16*0.625+w32*0.25+w64*0.125
    weather=fbm(perlin,2,4)
    A=np.clip((weather-weather.min())/(weather.max()-weather.min()),0,1)
    vol=np.stack([R,G,B,A],axis=-1)
    vol=(vol-vol.reshape(-1,4).min(0))/(np.ptp(vol.reshape(-1,4),0)+1e-6)
    vol=np.uint8(np.clip(vol*255+0.5,0,255))
    atlas=np.zeros((ROWS*TILE,COLS*TILE,4),np.uint8)
    idx=(np.arange(TILE)-1)%N
    for z in range(N):
        sl=vol[:,:,z][np.ix_(idx,idx)]          # sl[x,y] with wrapped border
        r,c=divmod(z,COLS)
        atlas[r*TILE:(r+1)*TILE,c*TILE:(c+1)*TILE]=sl.transpose(1,0,2)   # rows=y, cols=x
    img=Image.fromarray(atlas,'RGBA')
    names=['ss_air-trans-misc']+[f'ss_p_{f}-misc' for f in ('north','south','east','west','front','back')]
    for n in names: img.save(MAPS/f'{n}.png',compress_level=6)
    img.resize((1040,520)).save(ROOT/'artifacts/planet/cloud-noise-preview.png')
    print('Cloud noise atlas',img.size,'->',len(names),'materials')
if __name__=='__main__':main()
