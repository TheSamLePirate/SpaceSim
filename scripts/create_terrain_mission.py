"""Create a separate terrain proof mission; leave Escorte Aurore untouched."""
from pathlib import Path
import math
import re
from build_terrain import height

ROOT = Path(__file__).resolve().parent.parent
DATA = ROOT/'mods/terrain/data'
GAME = Path.home()/'Library/Application Support/io.github.KnossosNET.Knossos_NET/FreespaceOpen/FotG_R/FotG_R-1.1.2'
IDENTITY='1, 0, 0,\n 0, 1, 0,\n 0, 0, 1'


def build(automatic=False):
    text=(GAME/'data/missions/sp/___Template_Default_SP.fs2').read_text()
    name='[Rebel] Terrain - Validation auto' if automatic else '[Rebel] Terrain - Sol vers espace'
    text=text.replace('XSTR("[Faction] Mission Name", 3000)',f'XSTR("{name}", -1)')
    text=text.replace('$Author: username','$Author: Olivier Veinand / SpaceSim')
    text=re.sub(r'\$Mission Desc:.*?\$end_multi_text', '$Mission Desc:\n XSTR("Prototype SpaceSim : terrain physique 8 x 8 km, canyon et ascension continue vers le Vigilance a 6 km. Aucun changement de mission pendant le trajet.", -1)\n$end_multi_text',text,flags=re.S)
    text=text.replace('+Viewer pos: -0.220215, 76.418900, -279.230408','+Viewer pos: 2200, 6000, -6500')
    def section(start,end,content):
        nonlocal text
        a=text.index(start);b=text.index(end,a)
        text=text[:a]+content.strip()+'\n\n'+text[b:]
    section('#Briefing','#Debriefing_info',f'''#Briefing
$start_briefing
$num_stages: 1
$start_stage
$multi_text
 XSTR("SPACESIM / TERRAIN 01\n\nDepart dans une vallee rocheuse. Le sol et les montagnes ont une vraie geometrie et des collisions.\n\nVolez dans la vallee, puis prenez de la hauteur pour rejoindre le destroyer Vigilance, situe a 6 km. Vous restez dans la meme mission pendant tout le trajet.\n\nLe panneau de test indique l'altitude au-dessus du terrain et les contacts physiques. Le mode Auto effectue un passage de demonstration.", -1)
$end_multi_text
$voice: none.wav
$camera_pos: 2000, 5000, -6000
$camera_orient:
 1, 0, 0,
 0, 0.707107, 0.707107,
 0, -0.707107, 0.707107
$camera_time: 500
$num_lines: 0
$num_icons: 0
$Flags: 0
$Formula: ( true )
$end_stage
$end_briefing''')
    section('#Debriefing_info','#Players','''#Debriefing_info
$Num stages: 1
$Formula: ( true )
$Multi text
 XSTR("Fin du test de terrain SpaceSim. Le rapport technique est enregistre dans spacesim-terrain-telemetry.txt.", -1)
$end_multi_text
$Voice: none.wav
$Recommendation text:
 XSTR("Le mode libre reste ouvert pour comparer les montagnes, le fond de vallee et la montee vers le destroyer.", -1)
$end_multi_text''')
    section('#Players','#Objects','''#Players
$Starting Shipname: Red 1
$Ship Choices: ( "T-65c X-wing#Red" 1 )
+Weaponry Pool: ( "T&B KX-9" 1 "Krupx MG7-A#Pnk" 6 )''')
    def ship(name,cls,loc,player=False,ai=''):
        flags='"cargo-known" "invulnerable" "no-dynamic" "no-arrival-warp" "no-departure-warp"'
        if player:flags+=' "player-start"'
        return f'''$Name: {name}
$Class: {cls}
$Team: Friendly
$Location: {loc}
$Orientation:
 {IDENTITY}
{('$AI Goals: ( goals '+ai+' )'+chr(10)) if ai else ''}$Cargo 1: XSTR("Prototype", -1)
+Subsystem: Pilot
$Arrival Location: Hyperspace
$Arrival Cue: ( true )
$Departure Location: Hyperspace
$Departure Cue: ( false )
$Determination: 10
+Flags: ( {flags} )
+Flags2: ( )
+Respawn priority: 0
+Group: 0
+Use Table Score:
+Score: 0
'''
    probe_height=height(1000,-1000)+100
    objects=[ship('Red 1','T-65c X-wing#Red','0, 320, -2400',True),ship('Vigilance','Imperial Star Destroyer','0, 6000, 900',ai='( ai-play-dead 89 )'),ship('Sonde collision','T-65c X-wing#Blue',f'1000, {probe_height:.6f}, -1000',ai='( ai-play-dead 89 )')]
    section('#Objects','#Wings','#Objects ;! 3 total\n\n'+'\n'.join(objects))
    section('#Wings','#Events',f'''#Wings
$Name: Red
$Waves: 1
$Wave Threshold: 0
$Special Ship: 0
$Arrival Location: Hyperspace
$Arrival Cue: ( true )
$Departure Location: Hyperspace
$Departure Cue: ( false )
$Ships: ( "Red 1" )
+Hotkey: 0
+Flags: ( )

#Props
$Name: Terrain Aurore
$Class: SpaceSim Terrain
$Location: 0, 0, 0
$Orientation:
 {IDENTITY}
+Flags: ( )''')
    event=lambda n,c,a:f'$Formula: ( when {c} {a} )\n+Name: {n}\n+Repeat Count: 1\n+Interval: 1\n'
    events=[event('TerrainProof','( true )','( do-nothing )'),event('EnableDynamicMusic','( true )','( do-nothing )'),event('Bloquer hyperspace','( true )','( set-player-warp-status ( false ) )'),event('Consigne terrain','( has-time-elapsed 2 )','( send-message "#Command" "High" "Bienvenue" )')]
    if automatic:events.append(event('TerrainAutoTest','( true )','( do-nothing )'))
    section('#Events','#Goals','#Events\n\n'+'\n'.join(events))
    section('#Goals','#Waypoints','''#Goals
$Type: Primary
+Name: Rejoindre Vigilance
$MessageNew: XSTR("Monter au-dessus de 5 km et approcher Vigilance a moins de 3,6 km.", -1)
$end_multi_text
$Formula: ( and ( > ( get-object-y "Red 1" ) 5000 ) ( < ( distance "Red 1" "Vigilance" ) 3600 ) )
+Score: 0''')
    section('#Waypoints','#Messages','''#Waypoints
$Name: JumpOutPoint
$List: ( ( 0, 320, -2600 ) )
$Name: Approche Vigilance
$List: ( ( 0, 5500, -1800 ) )''')
    section('#Messages','#Reinforcements','''#Messages
$Command Persona: Rebel Commander 1
$Name: Bienvenue
$Team: -1
$MessageNew: XSTR("Red 1, le terrain est physique. Prenez la vallee puis montez vers Vigilance. Le trajet est continu et sans chargement.", -1)
$end_multi_text''')
    # Use the real terrain as the ground; remove the template's decorative planet.
    section('#Background bitmaps','#Asteroid Fields','''#Background bitmaps
$Num stars: 1200
$Ambient light level: 7895160
$Bitmap List:
+Flags: ( "corrected angles" )
$Sun: SunWhite
+Angles: 0.650000 0.400000 2.200000
+Scale: 2.000000''')
    path=DATA/'missions'/('_SPT_Terrain_Auto.fs2' if automatic else '_SPT_Terrain_Libre.fs2')
    path.write_text(text)
    print(path)


def main():
    for auto in [False,True]:build(auto)
    (DATA/'tables/spacesim-prp.tbm').write_text('''#PROPS
$Name: SpaceSim Terrain
$POF file: ss_terrain.pof
$Detail distance: ( 0 10000 )
$Flags: ( )
#End
''')
    (DATA/'tables/spacesim-mod.tbm').write_text('''#GAME SETTINGS
$Window title: SpaceSim - Terrain
$Mod title: SpaceSim Terrain
$Fix scripted velocity: YES
#END
''')

if __name__=='__main__':main()
