import numpy as np
from PIL import Image
from build_planet import FACES,DATA,mesh,pof,directions,fbm,COORDS,KNOTS
for face in FACES:
    name='ss_c_'+face[0]
    pof(DATA/'models'/f'{name}.pof',[mesh(face,48,shell=4200)],[name+'-trans'])
    size=2048;ax=np.interp(np.linspace(0,1,size),COORDS,KNOTS);u,v=np.meshgrid(ax,ax);d=directions(face,u,v)
    weather=fbm(d[...,0]*5+2,d[...,1]*5+5,d[...,2]*5,4)
    warp=fbm(d[...,0]*12,d[...,1]*12,d[...,2]*12,4)
    f=fbm(d[...,0]*38+warp*3,d[...,1]*38+warp*3,d[...,2]*38,6)
    opacity=np.clip((weather-.43)*8,0,1)*np.clip((f-.35)*4,0,.86)
    rgb=np.empty((size,size,4),dtype=np.uint8);rgb[:,:,:3]=np.uint8((.58+f[...,None]*.65)*255);rgb[:,:,3]=np.uint8(opacity*255)
    Image.fromarray(rgb).save(DATA/'maps'/f'{name}-trans.png')
    print('Cloud',face[0],flush=True)
