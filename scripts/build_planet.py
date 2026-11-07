"""A complete 160 km original planet, native POF meshes and generated materials.
Build with .venv/bin/python scripts/build_planet.py. No engine modification.
The adaptive cube grid concentrates geometry/texture resolution in the landing area.
"""
from pathlib import Path
import math, json, time
import numpy as np
from PIL import Image
from build_terrain import pack,vec,string,chunk,bsp,bounds
ROOT=Path(__file__).resolve().parent.parent
DATA=ROOT/'mods/planet/data'
R=80000.
# 2/3 of each face's samples cover the central 16 km; outer edges still match.
KNOTS=np.array([-1.,-.1,.1,1.])
COORDS=np.array([0.,1/6,5/6,1.])
FACES=[('north',(0,1,0),(1,0,0),(0,0,1)),('south',(0,-1,0),(1,0,0),(0,0,-1)),('east',(1,0,0),(0,0,-1),(0,1,0)),('west',(-1,0,0),(0,0,1),(0,1,0)),('front',(0,0,1),(1,0,0),(0,-1,0)),('back',(0,0,-1),(-1,0,0),(0,-1,0))]
def noise(x,y,z):
    ix,iy,iz=np.floor(x),np.floor(y),np.floor(z)
    fx,fy,fz=x-ix,y-iy,z-iz
    fx,fy,fz=[a*a*(3-2*a) for a in (fx,fy,fz)]
    def h(a,b,c):
        q=np.sin(a*127.1+b*311.7+c*74.7)*43758.5453
        return q-np.floor(q)
    mix=lambda a,b,t:a+(b-a)*t
    return mix(mix(mix(h(ix,iy,iz),h(ix+1,iy,iz),fx),mix(h(ix,iy+1,iz),h(ix+1,iy+1,iz),fx),fy),mix(mix(h(ix,iy,iz+1),h(ix+1,iy,iz+1),fx),mix(h(ix,iy+1,iz+1),h(ix+1,iy+1,iz+1),fx),fy),fz)
def fbm(x,y,z,octaves=5):
    v=0.;a=.5
    for k in range(octaves):
        v=v+a*noise(x,y,z);x,y,z=x*2.03+11.3,y*2.03+7.1,z*2.03-5.7;a*=.5
    return v

def elevation(d):
    x,y,z=[d[...,k] for k in range(3)]
    continental=fbm(x*3+8,y*3+3,z*3-4)
    mountains=np.maximum(0,(continental-.43))*11500
    # Continuous across all six faces. This is the same terrain in orbit and at ground.
    px,pz=x*R,z*R
    valley_center=650*np.sin(pz/2700)+180*np.sin(pz/730)
    dist=np.abs(px-valley_center)
    walls=2450*(1-np.exp(-(dist/1700)**2))
    ridges=1-np.abs(2*noise(px/1150, y*0+4,pz/1150)-1)
    local=230+70*np.sin(pz/950)+walls*(.55+.65*ridges)
    local+=370*noise(px/270,y*0+3,pz/270)*np.minimum(1,dist/1000)
    blend=np.exp(-((px/17000)**4+(pz/23000)**4))*np.clip((y-.75)*12,0,1)
    return np.maximum(0,mountains*(1-blend)+local*blend)

def directions(face,u,v):
    _,n,a,b=face
    d=np.stack([n[k]+u*a[k]+v*b[k] for k in range(3)],axis=-1)
    return d/np.linalg.norm(d,axis=-1,keepdims=True)

def mesh(face,n=192,shell=0,inward=False):
    axis=np.linspace(-1,1,n+1) if shell<0 else np.interp(np.linspace(0,1,n+1),COORDS,KNOTS)
    if shell<0:shell=-shell
    u,v=np.meshgrid(axis,axis)
    d=directions(face,u,v)
    h=elevation(d) if not shell else np.full_like(u,shell)
    p=d*(R+h)[...,None]
    vertices=[tuple(t) for t in p.reshape(-1,3)]
    tex=[(ix/n,iz/n) for iz in range(n+1) for ix in range(n+1)]
    faces=[]
    for j in range(n):
        for i in range(n):
            a=j*(n+1)+i;b=a+1;c=a+n+1;dd=c+1
            # Select outward winding using the actual cube-face basis.
            f=(a,c,b)
            pa,pb,pc=[np.array(vertices[k]) for k in f]
            out=np.dot(np.cross(pb-pa,pc-pa),pa)>0
            faces.extend([(a,c,b),(b,c,dd)] if out!=inward else [(a,b,c),(b,dd,c)])
    return vertices,faces,tex

def pof(path,meshes,textures):
    lo,hi=bounds(meshes[0][0]);radius=max(math.sqrt(sum(t*t for t in v)) for v in meshes[0][0])
    hdr=pack('fii',radius,0,len(meshes))+vec(lo)+vec(hi)+pack('i',len(meshes))+pack('i'*len(meshes),*range(len(meshes)))+pack('i',0)
    hdr+=pack('f',1e12)+vec((0,0,0))+vec((.001,0,0))+vec((0,.001,0))+vec((0,0,.001))+pack('ii',0,0)
    data=b'PSPO'+pack('i',2117)+chunk('HDR2',hdr)
    for i,(vs,fs,uv) in enumerate(meshes):
        tree=bsp(vs,fs,uv)
        data+=chunk('OBJ2',pack('ifi',i,radius,-1)+vec((0,0,0))+vec((0,0,0))+vec(lo)+vec(hi)+string(f'detail{i}')+string('')+pack('iii',0,-1,0)+pack('i',len(tree))+tree)
    data+=chunk('TXTR',pack('i',len(textures))+b''.join(string(t) for t in textures))
    path.write_bytes(data)
    return {'vertices':len(meshes[0][0]),'triangles':len(meshes[0][1]),'bytes':len(data),'bounds':[lo,hi]}

def materials(face,size):
    """Row batches avoid multi-GB working sets for the 8192-pixel landing atlas."""
    name='ss_p_'+face[0]
    outputs={key:Image.new('RGBA' if key=='normal' else 'RGB',(size,size)) for key in ('color','normal','shine')}
    ax=np.interp(np.linspace(0,1,size),COORDS,KNOTS).astype(np.float32)
    for row in range(0,size,128):
        u,v=np.meshgrid(ax,ax[row:row+128]);d=directions(face,u,v);h=elevation(d)
        x,y,z=[d[...,k]*R for k in range(3)]
        grain=fbm(x/24+3,y/24,z/24,4)-.45
        strata=np.sin(h/17+noise(x/180,y/180,z/180)*5)
        snow=np.clip((h-2100)/700+grain*.7,0,.92)
        vegetation=np.clip((.62-fbm(x/600,y/600,z/600))*2.2,0,.8)*(1-snow)
        rock=np.stack([.48+grain*.28+strata*.035,.37+grain*.23+strata*.028,.28+grain*.18+strata*.022],axis=-1)
        green=np.array([.17,.27,.17]);rock=rock*(1-vegetation[...,None])+green*vegetation[...,None]
        rgb=rock*(1-snow[...,None])+np.array([.82,.87,.88])*snow[...,None]
        shore=np.clip(h/75,0,1)
        ocean=np.stack([.025+h*0,.13+h*0,.19+h*0],axis=-1)+grain[...,None]*.035
        rgb=ocean*(1-shore[...,None])+rgb*shore[...,None]
        # Tangent-space microdetail from the albedo's procedural stone field.
        dx=np.gradient(grain,axis=1)*1.6+np.gradient(strata,axis=1)*.10
        dy=np.gradient(grain,axis=0)*1.6+np.gradient(strata,axis=0)*.10
        norm=np.stack([-dx,dy,np.ones_like(dx)],axis=-1);norm/=np.linalg.norm(norm,axis=-1,keepdims=True)
        shine=np.where(h<8,.68,.04+snow*.04)
        for key,arr in [('color',rgb),('normal',norm*.5+.5),('shine',np.repeat(shine[...,None],3,axis=-1))]:
            pixels=np.uint8(np.clip(arr*255,0,255))
            if key=='normal': pixels=np.stack([np.full_like(pixels[:,:,0],255),pixels[:,:,1],np.full_like(pixels[:,:,0],255),pixels[:,:,0]],axis=-1)
            outputs[key].paste(Image.fromarray(pixels),(0,row))
    for key,img in outputs.items():
        suffix={'color':'','normal':'-normal','shine':'-shine'}[key]
        img.save(DATA/'maps'/f'{name}{suffix}.png',compress_level=3)
    outputs['color'].resize((1200,1200)).save(ROOT/'artifacts/planet'/f'{name}-preview.jpg',quality=92)


def sky():
    n=64
    # Cube faces in one skybox model, with texture seams sharing the same sky function.
    meshes=[];vs=[];fs=[];uv=[];tids=[]
    # Custom POF with 6 texture slots needs one BSP using material IDs.
    for fi,face in enumerate(FACES):
        v,f,t=mesh(face,24,shell=1000,inward=True)
        offset=len(vs);vs.extend([tuple(q/80 for q in p) for p in v]);fs.extend([tuple(i+offset for i in faceids) for faceids in f]);uv.extend(t);tids.extend([fi]*len(f))
        sz=1024;axis=np.interp(np.linspace(0,1,sz),COORDS,KNOTS);u,vv=np.meshgrid(axis,axis);d=directions(face,u,vv)
        height_=np.clip(d[...,1],0,1)
        rgb=np.array([.57,.72,.79])+(np.array([.055,.25,.49])-np.array([.57,.72,.79]))*height_[...,None]**.45
        cloud=fbm(d[...,0]*8+2,d[...,1]*8+5,d[...,2]*8,5)
        cloud=np.clip((cloud-.50)*7,0,.85)*np.clip(height_*5,0,1)
        rgb=rgb*(1-cloud[...,None])+np.array([.90,.92,.91])*cloud[...,None]
        Image.fromarray(np.uint8(np.clip(rgb*255,0,255))).save(DATA/'maps'/f'ss_sky_{fi}.png')
    # Write one mesh by reusing POF wrapper then replacing its BSP texture IDs.
    lo,hi=bounds(vs);rad=1100.
    hdr=pack('fii',rad,0,1)+vec(lo)+vec(hi)+pack('iii',1,0,0)+pack('f',1e9)+vec((0,0,0))+vec((.001,0,0))+vec((0,.001,0))+vec((0,0,.001))+pack('ii',0,0)
    tree=bsp(vs,fs,uv,tids)
    obj=pack('ifi',0,rad,-1)+vec((0,0,0))+vec((0,0,0))+vec(lo)+vec(hi)+string('detail0')+string('')+pack('iii',0,-1,0)+pack('i',len(tree))+tree
    (DATA/'models/ss_planet_sky.pof').write_bytes(b'PSPO'+pack('i',2117)+chunk('HDR2',hdr)+chunk('OBJ2',obj)+chunk('TXTR',pack('i',6)+b''.join(string(f'ss_sky_{i}') for i in range(6))))


def main():
    import sys
    for folder in ['maps','models','tables','missions']:(DATA/folder).mkdir(parents=True,exist_ok=True)
    info=[]
    for face in FACES:
        print('Building',face[0],flush=True)
        if '--textures-only' not in sys.argv:
            item=pof(DATA/'models'/f'ss_p_{face[0]}.pof',[mesh(face,192),mesh(face,96),mesh(face,48)],['ss_p_'+face[0]])
            item['face']=face[0];info.append(item)
        if '--mesh-only' not in sys.argv:materials(face,8192 if face[0]=='north' else 2048)
    if '--mesh-only' not in sys.argv:sky()
    if info:
        (ROOT/'artifacts/planet/geometry.json').write_text(json.dumps({'radius_m':R,'diameter_km':160,'area_km2':4*math.pi*(R/1000)**2,'central_detail_width_km':16,'central_grid_m':125,'triangles':sum(i['triangles'] for i in info),'faces':info},indent=2)+'\n')
    # Three transparent, unlit shells approximate the atmospheric limb. No collisions.
    if '--textures-only' not in sys.argv:
        for idx,alt in enumerate([4500,5500,6800]):
            vs=[];fs=[];uv=[]
            for face in FACES:
                vv,ff,tt=mesh(face,24,shell=alt);off=len(vs);vs+=vv;fs +=[tuple(i+off for i in f) for f in ff];uv+=tt
            pof(DATA/'models'/f'ss_atmo_{idx}.pof',[(vs,fs,uv)],['ss_air-trans'])
        Image.new('RGBA',(1,1),(85,160,230,101)).save(DATA/'maps/ss_air-trans.png')
    print('Planet build complete',flush=True)
if __name__=='__main__':main()
