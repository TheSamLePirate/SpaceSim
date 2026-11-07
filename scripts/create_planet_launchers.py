from pathlib import Path
import plistlib,subprocess
root=Path(__file__).resolve().parents[1]
for mode,name,args in [(0,'Aurore - Vol libre','libre'),(1,'Aurore - Sol vers orbite','auto'),(2,'Aurore - FRED','fred'),(3,'Aurore - Test ombres','auto ombres')]:
 app=root/(name+'.app');mac=app/'Contents/MacOS';mac.mkdir(parents=True,exist_ok=True)
 (app/'Contents/Info.plist').write_bytes(plistlib.dumps({'CFBundleExecutable':'launch','CFBundleIdentifier':f'fr.spacesim.aurore.{mode}','CFBundleName':name,'CFBundlePackageType':'APPL','LSUIElement':True}))
 subprocess.run(['clang','-Os',f'-DPLANET_MODE={mode}',str(root/'scripts/planet_launcher.c'),'-o',str(mac/'launch')],check=True)
 cmd=root/(name+'.command');cmd.write_text('#!/bin/zsh\nPROJECT_DIR="${0:A:h}"\nexec "$PROJECT_DIR/scripts/run_planet.sh" '+args+'\n');cmd.chmod(0o755)
 print(app)
