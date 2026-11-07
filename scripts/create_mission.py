"""Build our first FotG mission from the installed official single-player template."""
from pathlib import Path
import re

PROJECT = Path(__file__).resolve().parent.parent
GAME = Path.home() / 'Library/Application Support/io.github.KnossosNET.Knossos_NET/FreespaceOpen/FotG_R/FotG_R-1.1.2'
DEST = PROJECT / 'missions/_SPT_A99_Aurore.fs2'
text = (GAME / 'data/missions/sp/___Template_Default_SP.fs2').read_text()
text = text.replace('XSTR("[Faction] Mission Name", 3000)', 'XSTR("[Rebel] Escorte Aurore", -1)')
text = text.replace('$Author: username', '$Author: Olivier Veinand')
text = re.sub(r'\$Created:.*', '$Created: 11/07/26 at 04:00:00', text)
text = re.sub(r'\$Modified:.*', '$Modified: 11/07/26 at 04:00:00', text)
text = re.sub(r'\$Mission Desc:.*?\$end_multi_text', '''$Mission Desc:
 XSTR("Premiere mission SpaceSim. Protegez le transport Aurore a bord de votre X-wing. Deux TIE attaquent; votre ailier Red 2 vous assiste. Apres leur destruction, Aurore passe en hyperespace et la mission se termine automatiquement.", -1)
$end_multi_text''', text, flags=re.S)
text = text.replace('+Viewer pos: -0.220215, 76.418900, -279.230408', '+Viewer pos: 300.000000, 2200.000000, -2500.000000')

def section(start, end, content):
    global text
    a = text.index(start)
    b = text.index(end, a)
    text = text[:a] + content.strip() + '\n\n' + text[b:]

section('#Briefing', '#Debriefing_info', '''#Briefing
$start_briefing
$num_stages: 1
$start_stage
$multi_text
 XSTR("Red 1, vous escortez le transport rebelle Aurore, charge de materiel medical.\n\nDeux chasseurs TIE se rapprochent par l'avant. Detruisez-les avec l'aide de Red 2 et gardez Aurore en vie. Le transport attend que la route soit libre avant de passer en hyperespace.\n\nLa mission se terminera automatiquement apres son depart. Aucun retour manuel n'est necessaire.", -1)
$end_multi_text
$voice: none.wav
$camera_pos: 0.000000, 3000.000000, -2500.000000
$camera_orient:
 1.000000, 0.000000, 0.000000,
 0.000000, 0.707107, 0.707107,
 0.000000, -0.707107, 0.707107
$camera_time: 500
$num_lines: 0
$num_icons: 0
$Flags: 0
$Formula: ( true )
$end_stage
$end_briefing''')
section('#Debriefing_info', '#Players', '''#Debriefing_info
$Num stages: 2
$Formula: ( has-departed-delay 0 "Aurore" )
$Multi text
 XSTR("Mission accomplie. Aurore a rejoint la flotte avec sa cargaison medicale. Les deux TIE ont ete neutralises. Belle premiere escorte, Red 1.", -1)
$end_multi_text
$Voice: none.wav
$Recommendation text:
 XSTR("Pour modifier cette mission dans FRED : deplacez les TIE, ajoutez un ennemi ou changez les objectifs dans les editeurs.", -1)
$end_multi_text
$Formula: ( is-destroyed-delay 0 "Aurore" )
$Multi text
 XSTR("Echec de l'escorte. Aurore a ete detruit. Recommencez et interceptez rapidement les TIE avant qu'ils ne concentrent leurs tirs sur le transport.", -1)
$end_multi_text
$Voice: none.wav
$Recommendation text:
 XSTR("Restez pres du transport et concentrez vos tirs sur un TIE a la fois. Red 2 vous accompagne.", -1)
$end_multi_text''')
section('#Players', '#Objects', '''#Players
$Starting Shipname: Red 1
$Ship Choices: (
 "T-65c X-wing#Red" 2
)
+Weaponry Pool: (
 "T&B KX-9" 2
 "Krupx MG7-A#Pnk" 12
)''')

identity = '1.000000, 0.000000, 0.000000,\n 0.000000, 1.000000, 0.000000,\n 0.000000, 0.000000, 1.000000'
facing_back = '-1.000000, 0.000000, 0.000000,\n 0.000000, 1.000000, 0.000000,\n 0.000000, 0.000000, -1.000000'
def ship(name, cls, team, location, *, ai='', player=False, escort=False, reverse=False, departure='( false )'):
    flags = ['cargo-known']
    if player: flags.append('player-start')
    if escort: flags += ['escort', 'no-dynamic']
    return f'''$Name: {name}
$Class: {cls}
$Team: {team}
$Location: {location}
$Orientation:
 {facing_back if reverse else identity}
{('$AI Goals: ( goals ' + ai + ' )' + chr(10)) if ai else ''}$Cargo 1: XSTR("{'Materiel medical' if escort else 'Nothing'}", -1)
+Subsystem: Pilot
$Arrival Location: Hyperspace
$Arrival Cue: ( true )
$Departure Location: Hyperspace
$Departure Cue: {departure}
$Determination: 10
+Flags: ( {' '.join('"'+f+'"' for f in flags)} )
+Flags2: ( )
+Respawn priority: 0
{'+Escort priority: 100' + chr(10) if escort else ''}+Group: 0
+Use Table Score:
+Score: 10
'''
objects = [
 ship('Red 1','T-65c X-wing#Red','Friendly','0, 0, 0',player=True),
 ship('Red 2','T-65c X-wing#Red','Friendly','-80, 0, -80',ai='( ai-guard "Aurore" 80 ) ( ai-chase-any 70 )'),
 ship('Aurore','GR-75 Transport','Friendly','400, -100, 700',escort=True,departure='( is-destroyed-delay 5 "Alpha" )'),
 ship('Alpha 1','TIE/ln Fighter','Hostile','-250, 150, 2800',ai='( ai-chase "Aurore" 70 ) ( ai-chase-any 60 )',reverse=True),
 ship('Alpha 2','TIE/ln Fighter','Hostile','250, -150, 3000',ai='( ai-chase "Aurore" 70 ) ( ai-chase-any 60 )',reverse=True),
]
section('#Objects','#Wings','#Objects ;! 5 total\n\n'+'\n'.join(objects))
def wing(name, ships, hotkey):
    return f'''$Name: {name}
$Waves: 1
$Wave Threshold: 0
$Special Ship: 0
$Arrival Location: Hyperspace
$Arrival Cue: ( true )
$Departure Location: Hyperspace
$Departure Cue: ( false )
$Ships: ( {' '.join('"'+s+'"' for s in ships)} )
+Hotkey: {hotkey}
+Flags: ( )
'''
section('#Wings','#Events','#Wings ;! 2 total\n\n'+wing('Red',['Red 1','Red 2'],0)+'\n'+wing('Alpha',['Alpha 1','Alpha 2'],3))
def event(name, condition, actions):
    return f'''$Formula: ( when {condition} {actions} )
+Name: {name}
+Repeat Count: 1
+Interval: 1
'''
events = [
 event('DestroyedSubsystemsReact','( true )','( do-nothing )'),
 event('EnableDynamicMusic','( true )','( do-nothing )'),
 event('Bloquer depart joueur','( true )','( set-player-warp-status ( false ) )'),
 event('Consigne escorte','( has-time-elapsed 2 )','( send-message "#Command" "High" "Ordres" )'),
 event('Route libre','( is-destroyed-delay 1 "Alpha" )','( send-message "Aurore" "High" "Depart" )'),
 event('Transport perdu','( is-destroyed-delay 1 "Aurore" )','( send-message "#Command" "High" "Echec" )'),
 event('Fin escorte','( or ( has-departed-delay 6 "Aurore" ) ( is-destroyed-delay 7 "Aurore" ) )','( end-mission )'),
]
section('#Events','#Goals','#Events ;! 7 total\n\n'+'\n'.join(events))
section('#Goals','#Waypoints', '''#Goals
$Type: Primary
+Name: Proteger Aurore
$MessageNew: XSTR("Proteger Aurore jusqu'a son depart en hyperespace.", -1)
$end_multi_text
$Formula: ( has-departed-delay 0 "Aurore" )
+Score: 500
$Type: Primary
+Name: Detruire les TIE
$MessageNew: XSTR("Detruire les deux chasseurs TIE de l'escadron Alpha.", -1)
$end_multi_text
$Formula: ( is-destroyed-delay 0 "Alpha" )
+Score: 250''')
messages = [('Ordres',"Red 1, protegez Aurore. Deux TIE arrivent droit devant. Red 2 vous couvre."),('Depart',"La route est libre. Merci pour la couverture, Red ! Aurore passe en hyperespace."),('Echec',"Aurore a ete detruit. Escorte perdue, abandonnez l'operation.")]
section('#Messages','#Reinforcements', '#Messages ;! 3 total\n\n$Command Persona: Rebel Commander 1\n\n'+'\n\n'.join(f'$Name: {n}\n$Team: -1\n$MessageNew: XSTR("{m}", -1)\n$end_multi_text' for n,m in messages))
DEST.write_text(text)
print(DEST)
