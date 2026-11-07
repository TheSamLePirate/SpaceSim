from pathlib import Path
import re,json
import numpy as np
from build_planet import R,FACES,DATA,ROOT
from build_planet_tiles import elevation
TILES=json.loads((ROOT/'artifacts/planet/tiles.json').read_text())
GROUND_FILE=ROOT/'artifacts/planet/ground.json'
GROUND=json.loads(GROUND_FILE.read_text()) if GROUND_FILE.exists() else dict(prop_classes=[],props=[],ships=[])
VEG_FILE=ROOT/'artifacts/planet/vegetation.json'
if VEG_FILE.exists():
    # Vegetation sectors replace the older per-patch forests and rock fields.
    GROUND['props']=[g for g in GROUND['props'] if not g['name'].startswith('Nature')]
    GROUND['prop_classes']=[c for c in GROUND['prop_classes'] if not (c['name'].startswith('SpaceSim Forest') or c['name'].startswith('SpaceSim Rocks'))]
    for v in json.loads(VEG_FILE.read_text()):
        cls='SpaceSim Veg '+v['name'][5:]
        GROUND['prop_classes'].append(dict(name=cls,pof=v['name']+'.pof',detail=[0,1100,4500,13000]))
        GROUND['props'].append(dict(name='Foret '+v['name'][5:],cls=cls,pos=v['pos'],orient=[[1,0,0],[0,1,0],[0,0,1]]))
def orient_text(o):
    return ',\n '.join(', '.join(f'{c:.6f}' for c in row) for row in o)
def ship_text(sh):
    return f'''$Name: {sh['name']}
$Class: {sh['cls']}
$Team: {sh['team']}
$Location: {sh['pos'][0]:.3f}, {sh['pos'][1]:.3f}, {sh['pos'][2]:.3f}
$Orientation:
 {orient_text(sh['orient'])}
$Cargo 1: XSTR("Garnison", -1)
$Arrival Location: Hyperspace
$Arrival Cue: ( true )
$Departure Location: Hyperspace
$Departure Cue: ( false )
$Determination: 10
+Flags: ( "cargo-known" "no-arrival-warp" "no-departure-warp" )
+Flags2: ( )
+Respawn priority: 0
+Group: 0
+Use Table Score:
+Score: 0
'''
BASE=ROOT/'mods/terrain/data/missions/_SPT_Terrain_Libre.fs2'
IDENTITY='1, 0, 0,\n 0, 1, 0,\n 0, 0, 1'
def build(auto=False):
    text=BASE.read_text()
    text=text.replace('[Rebel] Terrain - Sol vers espace','[Rebel] Aurore - Surface vers orbite')
    a=text.index('$Mission Desc:');b=text.index('$end_multi_text',a)
    text=text[:a]+'''$Mission Desc:
 XSTR("Aurore : planete physique de 160 km de diametre. Vallee detaillee, relief, ocean, atmosphere et montee continue vers Vigilance a 100 km. FSO 26.2, une seule mission.", -1)
'''+text[b:]
    text=re.sub(r'\$Skybox Model:.*?\+Skybox Flags: \d+', '$Skybox Model: skybox_starfield.pof\n+Skybox Flags: 1573120',text,flags=re.S)
    text=text.replace('+Fog Near Mult: 1.000000\n\n+Fog Far Mult: 1.000000','+Fog 1000m Visibility: 0.96\n+Fog Near Distance: 800\n+Fog Skybox Clip Distance: 0\n+Fog Clip Distance: 180000')
    # Native fog, no nebula sprites. Background model is the atmosphere sky.
    text=text.replace('+Flags: 0\n+Fog',f'+Flags: {1024 if auto else 0}\n+Fog',1)
    text=text.replace('$Ambient light level: 7895160','$Ambient light level: 1315860\n+Neb2Color: ( 136 172 188 )\n+Neb2 Poofs List: ( )')
    text=text.replace('$Num stars: 1200','$Num stars: 1600')
    text=text.replace('+Angles: 0.650000 0.400000 2.200000','+Angles: -0.620000 0.000000 0.800000')
    text=re.sub(r'(\$Sun: SunWhite\n\+Angles: [^\n]+\n\+Scale: )[\d.]+',r'\g<1>0.35',text)
    text=re.sub(r'\$Location: 0, 320, -2400', '$Location: 0, 480, -5000',text)
    # Actual local radial elevation at the initial location, including curvature.
    direction=np.array([0.,1.,-5000/R]);direction/=np.linalg.norm(direction)
    surface=direction*(R+float(elevation(direction)))+np.array([0,-R,0])
    start_y=surface[1]+320
    text=text.replace('$Location: 0, 480, -5000',f'$Location: 0, {start_y:.5f}, -5000')
    text=text.replace('$Location: 0, 6000, 900','$Location: 18500, 92000, 5000')
    direction=np.array([1000/R,1.,-1000/R]);direction/=np.linalg.norm(direction)
    probe_y=(direction*(R+float(elevation(direction))))[1]-R+120
    text=re.sub(r'(\$Name: Sonde collision.*?\$Location:) [^\n]+',rf'\1 1000, {probe_y:.5f}, -1000',text,flags=re.S)
    a=text.index('#Props');b=text.index('#Events',a)
    props=[]
    for t in TILES:
        c=t['center'];n=t['name'][4:]
        props.append(f'$Name: Planet {n}\n$Class: SpaceSim Tile {n}\n$Location: {c[0]:.3f}, {c[1]-R:.3f}, {c[2]:.3f}\n$Orientation:\n {IDENTITY}\n+Flags: ( )\n')
    for g in GROUND['props']:
        props.append(f"$Name: {g['name']}\n$Class: {g['cls']}\n$Location: {g['pos'][0]:.3f}, {g['pos'][1]:.3f}, {g['pos'][2]:.3f}\n$Orientation:\n {orient_text(g['orient'])}\n+Flags: ( )\n")
    props.append(f'$Name: Air 0\n$Class: SpaceSim Air 0\n$Location: 0, {-R:.0f}, 0\n$Orientation:\n {IDENTITY}\n+Flags: ( )\n')
    text=text[:a]+'#Props\n'+'\n'.join(props)+'\n'+text[b:]
    a=text.index('#Wings')
    text=text[:a]+'\n'.join(ship_text(sh) for sh in GROUND['ships'])+'\n'+text[a:]
    text=text.replace('TerrainProof','PlanetProof')
    text=text.replace('( > ( get-object-y "Red 1" ) 5000 )','( > ( get-object-y "Red 1" ) 95000 )')
    text=text.replace('Monter au-dessus de 5 km et approcher Vigilance a moins de 3,6 km.','Monter en orbite vers Vigilance (100 km). F8 : vol automatique ; F9 : vitesse de croisiere.')
    text=text.replace('SPACESIM / TERRAIN 01','SPACESIM / AURORE 02')
    a=text.index('$multi_text',text.index('#Briefing'));b=text.index('$end_multi_text',a)
    text=text[:a]+'''$multi_text
 XSTR("AURORE / DE LA SURFACE A L'ORBITE\n\nUne vraie petite planete de 160 km de diametre. La vallee, les montagnes et le globe visible depuis l'espace sont le meme terrain physique. Tout est charge avant le depart.\n\nF8 : demonstration automatique / reprendre les commandes.\nF9 : vitesse de croisiere 250 / 1500 / 5000 m/s. Les commandes normales de gaz restent actives.\n\nAu sol, restez a faible vitesse. En altitude, montez puis retournez-vous pour voir la courbure et la planete entiere. Vigilance vous attend a 100 km.\n\nPrototype de rendu FSO : relief, textures 8K, normales, atmosphere progressive, nuages et liseres atmospheriques.", -1)
'''+text[b:]
    text=text.replace('Red 1, le terrain est physique. Prenez la vallee puis montez vers Vigilance. Le trajet est continu et sans chargement.','Red 1, bienvenue sur Aurore. F8 lance le trajet sol-orbite. F9 change la vitesse de croisiere. Le terrain reste physique pendant tout le voyage.')
    path=DATA/'missions'/('_SPT_Planet_Auto.fs2' if auto else '_SPT_Planet_Libre.fs2');path.write_text(text)
    print('Mission',path,'start_y',start_y)
    return start_y

def build_evasion():
    """Cinematic mission: rebel camp at the canyon entrance, GR-75 'Aurore', Red 1-4 X-wings.
    Star Destroyers, TIEs, the Death Star and the destruction props are driven by spacesim-cine-sct.lua."""
    from build_planet_ground import surface, frame, valley_x
    text=(DATA/'missions/_SPT_Planet_Auto.fs2').read_text()
    text=text.replace('[Rebel] Aurore - Surface vers orbite','[Rebel] Aurore - Evasion (cinematique)')
    zc=-6350.0;xc=valley_x(zc)
    def at(dx,dz,lift,heading=0.0):
        p,up,_=surface(xc+dx,zc+dz);r,u,f=frame(up,heading)
        return p+up*lift,[list(r),list(u),list(f)]
    ships=[]
    pos,ori=at(0,0,10.6,0.12)
    ships.append(dict(name='Aurore',cls='GR-75 Transport',team='Friendly',pos=list(pos),orient=ori))
    for k,(dx,dz) in enumerate([(-70,-120),(70,-120),(-140,-60),(140,-60)]):
        pos,ori=at(dx,dz,45.0,0.12)
        ships.append(dict(name=f'Rouge {k+1}' if k else 'Red 1',cls='T-65c X-wing#Red',team='Friendly',pos=list(pos),orient=ori))
    # Red 1 keeps its player-start object; move it, then add the three wingmen
    a=text.index('$Name: Red 1');b=text.index('$Name:',a+5)
    blk=text[a:b]
    blk=re.sub(r'\$Location: [^\n]+','$Location: '+', '.join(f'{c:.3f}' for c in ships[1]['pos']),blk)
    blk=re.sub(r'\$Orientation:\n[^\n]+,\n[^\n]+,\n[^\n]+\n','$Orientation:\n '+orient_text(ships[1]['orient'])+'\n',blk)
    text=text[:a]+blk+text[b:]
    extra=[ships[0]]+ships[2:]
    a=text.index('#Wings')
    text=text[:a]+'\n'.join(ship_text(sh) for sh in extra)+'\n'+text[a:]
    # rebel camp decor (props): two pads, fuel tanks, a barracks and a comm mast
    camp=[('pad',0,0,0.12),('pad',-160,90,0.3),('tanks',150,80,1.4),('barracks',-170,-90,0.5),('tower',120,-150,0.0)]
    props=[]
    for k,(kind,dx,dz,hd) in enumerate(camp):
        pos,ori=at(dx,dz,-0.6 if kind=='pad' else -0.8,hd)
        props.append(f"$Name: Camp {kind} {k}\n$Class: SpaceSim {kind.title()}\n$Location: {pos[0]:.3f}, {pos[1]:.3f}, {pos[2]:.3f}\n$Orientation:\n {orient_text(ori)}\n+Flags: ( )\n")
    for name,cls in [('Etoile Noire','SpaceSim Death Star'),('Noyau','SpaceSim Core')]:
        props.append(f"$Name: {name}\n$Class: {cls}\n$Location: 0, -80000, 9000000\n$Orientation:\n {IDENTITY}\n+Flags: ( )\n")
    a=text.index('#Props')+len('#Props\n')
    text=text[:a]+'\n'.join(props)+'\n'+text[a:]
    # ---- clean-up of the free-flight leftovers (Evasion is a real mission, not a terrain proof)
    def drop_object(t,name):
        a=t.index(f'$Name: {name}\n');b=t.index('$Name:',a+5)
        return t[:a]+t[b:]
    for name in ['Vigilance','Sonde collision']:
        text=drop_object(text,name)
    a=text.index('$Name: Red 1\n');b=text.index('$Name:',a+5)
    text=text[:a]+text[a:b].replace(' "invulnerable"','').replace(' "no-dynamic"','')+text[b:]
    # guide beacons: visible decor, but neither on the radar nor in the target list
    text=re.sub(r'(\$Name: Balise [^\n]+\n(?:(?!\$Name:).)*?\+Flags: \( "cargo-known")',r'\1 "hidden-from-sensors"',text,flags=re.S)
    a=text.index('#Events');b=text.index('#Waypoints',a)
    batteries=' '.join(f'"Batterie {k}"' for k in range(1,11))
    text=text[:a]+f'''#Events

$Formula: ( when ( true ) ( do-nothing ) )
+Name: PlanetProof
+Repeat Count: 1
+Interval: 1

$Formula: ( when ( true ) ( do-nothing ) )
+Name: EnableDynamicMusic
+Repeat Count: 1
+Interval: 1

$Formula: ( when ( true ) ( set-player-warp-status ( false ) ) )
+Name: Bloquer hyperspace
+Repeat Count: 1
+Interval: 1

$Formula: ( when ( true ) ( add-remove-escort "Aurore" 100 ) )
+Name: Escorte Aurore
+Repeat Count: 1
+Interval: 1

#Goals
$Type: Primary
+Name: Proteger l'Aurore
$MessageNew: XSTR("Escorter l'Aurore jusqu'au saut en hyperespace", -1)
$end_multi_text
$Formula: ( has-departed-delay 0 "Aurore" )
+Score: 0

$Type: Primary
+Name: Batteries
$MessageNew: XSTR("Detruire les 10 batteries turbolaser du canyon", -1)
$end_multi_text
$Formula: ( is-destroyed-delay 0 {batteries} )
+Score: 0

'''+text[b:]
    text=re.sub(r'\$Name: Approche Vigilance\n\$List: [^\n]+\n','',text)
    a=text.index('#Messages');b=text.index('#Reinforcements',a)
    text=text[:a]+'#Messages\n\n'+text[b:]
    a=text.index('$multi_text',text.index('#Briefing'));b=text.index('$end_multi_text',a)
    text=text[:a]+'''$multi_text
 XSTR("AURORE - EVASION\n\nTrois destroyers stellaires viennent de sortir de l'hyperespace. Le cargo Aurore decolle du camp a l'entree du canyon avec nos derniers techniciens.\n\nEscadron Rouge : ouvrez la route. Detruisez les dix batteries turbolaser qui gardent le canyon, protegez l'Aurore jusqu'en orbite, puis sautez en hyperespace avec elle.\n\nAttention au relief : en atmosphere, votre X-wing vole comme un avion.", -1)
'''+text[b:]
    a=text.index('$Mission Desc:');b=text.index('$end_multi_text',a)
    text=text[:a]+'''$Mission Desc:
 XSTR("Aurore - Evasion. Le cargo rebelle Aurore fuit par le canyon sous le feu imperial, monte en orbite et doit sauter en hyperespace avant l'arrivee de l'Etoile Noire. Escadron Rouge : escorte.", -1)
'''+text[b:]
    n=text[text.index('#Objects'):text.index('#Wings')].count('$Name:')
    text=re.sub(r'#Objects\s*;! \d+ total','#Objects ;! %d total'%n,text)
    path=DATA/'missions/_SPT_Aurore_Evasion.fs2';path.write_text(text)
    print('Mission',path,'cargo at',[round(c) for c in ships[0]['pos']])

def main():
    for auto in [False,True]:build(auto)
    lines=['#PROP CATEGORIES','$Name: SpaceSim World','+Color: ( 100 180 220 )','#PROPS']
    for t in TILES:
        e=t['extent_m'];n=t['name'][4:]
        lines+= [f'$Name: SpaceSim Tile {n}',f'$POF file: {t["name"]}.pof','$Closeup_pos: 0, 0, -200000',f'$Detail distance: ( 0 {int(e*0.7)} {int(e*2.2)} )','$Category: SpaceSim World','$Flags: ( )','']
    for g in GROUND['prop_classes']:
        flags='( "no_collide" )' if g['name'].startswith('SpaceSim Veg') else '( )'   # trees never stop weapons
        lines += [f"$Name: {g['name']}",f"$POF file: {g['pof']}",'$Closeup_pos: 0, 0, -300',f"$Detail distance: ( {' '.join(str(d) for d in g['detail'])} )",'$Category: SpaceSim World',f'$Flags: {flags}','']
    lines += ['$Name: SpaceSim Death Star','$POF file: ss_deathstar.pof','$Closeup_pos: 0, 0, -60000','$Detail distance: ( 0 260000 )','$Category: SpaceSim World','$Flags: ( "no_collide" )','']
    for si in range(3):
        for sh in range(4):
            lines += [f'$Name: SpaceSim Frag {si}{sh}',f'$POF file: ss_frag{si}{sh}.pof','$Closeup_pos: 0, 0, -30000','$Detail distance: ( 0 )','$Category: SpaceSim World','$Flags: ( "no_collide" )','']
    lines += ['$Name: SpaceSim Core','$POF file: ss_core.pof','$Closeup_pos: 0, 0, -300000','$Detail distance: ( 0 )','$Category: SpaceSim World','$Flags: ( "no_collide" "no lighting" )','']
    for i in range(1):
        lines += [f'$Name: SpaceSim Air {i}',f'$POF file: ss_atmo_{i}.pof','$Closeup_pos: 0, 0, -200000','$Detail distance: ( 0 )','$Category: SpaceSim World','$Flags: ( "no_collide" )','']
    lines+=['#End'];(DATA/'tables/spacesim-prp.tbm').write_text('\n'.join(lines)+'\n')
    (DATA/'tables/spacesim-mod.tbm').write_text('''#GAME SETTINGS
$Window title: SpaceSim - Aurore 02
$Mod title: SpaceSim Aurore
$Fix scripted velocity: YES
#GRAPHICS SETTINGS
$Enable External Shaders: YES
$Max draw distance: 1000000
$Shadow Cascade Distances: ( 120 420 1500 5000 )
$Min draw distance: 20
#END
''')
    build_evasion()
if __name__=='__main__':main()
