#!/bin/zsh
set -e
PROJECT_DIR="${0:A:h:h}"
LIBRARY_DIR="$HOME/Library/Application Support/io.github.KnossosNET.Knossos_NET/FreespaceOpen"
MODE="${1:-libre}"
MISSION="_SPT_Terrain_Libre"
[[ "$MODE" == "auto" ]] && MISSION="_SPT_Terrain_Auto"
if [[ ! -e "$LIBRARY_DIR/SpaceSimTerrain" ]]; then
  ln -s "$PROJECT_DIR/mods/terrain" "$LIBRARY_DIR/SpaceSimTerrain"
fi
# FSO on macOS searches mods next to its .app, not in the working directory.
ENGINE_DIR="$PROJECT_DIR/tools/FSO-26.2.0"
for MOD in FotG_R SpaceSimPlanet SpaceSimTerrain; do
  [[ -e "$ENGINE_DIR/$MOD" || ! -e "$LIBRARY_DIR/$MOD" ]] || ln -s "$LIBRARY_DIR/$MOD" "$ENGINE_DIR/$MOD"
done
cd "$LIBRARY_DIR"
if [[ "$MODE" == "fred" ]]; then
  exec "$PROJECT_DIR/tools/FSO-26.2.0/qtfred_26_2_0_arm64.app/Contents/MacOS/qtfred_26_2_0_arm64" -mod "SpaceSimTerrain,FotG_R/FotG_R-1.1.2" -start_mission "$PROJECT_DIR/mods/terrain/data/missions/$MISSION.fs2" -parse_cmdline_only
else
  exec "$PROJECT_DIR/tools/FSO-26.2.0/fs2_open_26_2_0_arm64.app/Contents/MacOS/fs2_open_26_2_0_arm64" -mod "SpaceSimTerrain,FotG_R/FotG_R-1.1.2" -start_mission "$MISSION" -window -res 1440x900 -parse_cmdline_only
fi
