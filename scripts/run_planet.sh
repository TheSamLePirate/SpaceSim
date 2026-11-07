#!/bin/zsh
set -e
PROJECT_DIR="${0:A:h:h}"
LIBRARY_DIR="$HOME/Library/Application Support/io.github.KnossosNET.Knossos_NET/FreespaceOpen"
MODE="${1:-libre}"
PROFILE="${2:-qualite}"
# Vulkan (MoltenVK) by default: shadows are 2x cheaper than with OpenGL 4.1 on macOS (no geometry-shader
# cascade fallback). *_gl profiles keep the OpenGL renderer. Measured: docs/AURORE-03.md, "Phase 2".
SHADOW_FLAGS=( -vulkan -enable_shadows -shadow_quality 2 -anisotropic_filter 16 )
[[ "$PROFILE" == "max" || "$PROFILE" == "vk" ]] && SHADOW_FLAGS=( -vulkan -enable_shadows -shadow_quality 3 -anisotropic_filter 16 -soft_particles )
[[ "$PROFILE" == "ultra" ]] && SHADOW_FLAGS=( -vulkan -enable_shadows -shadow_quality 4 -anisotropic_filter 16 -soft_particles )
[[ "$PROFILE" == "rapide" ]] && SHADOW_FLAGS=( -vulkan -shadow_quality 0 )
[[ "$PROFILE" == "qualite_gl" ]] && SHADOW_FLAGS=( -shadow_quality 0 )
[[ "$PROFILE" == "ombres" ]] && SHADOW_FLAGS=( -enable_shadows -shadow_quality 2 )
[[ "$PROFILE" == "max_gl" ]] && SHADOW_FLAGS=( -enable_shadows -shadow_quality 3 -anisotropic_filter 16 -soft_particles )
[[ "$PROFILE" == "max_msaa" ]] && SHADOW_FLAGS=( -enable_shadows -shadow_quality 4 -msaa 4 -anisotropic_filter 16 -soft_particles )
MISSION="_SPT_Planet_Libre"
[[ "$MODE" == "auto" ]] && MISSION="_SPT_Planet_Auto"
[[ "$MODE" == "evasion" ]] && MISSION="_SPT_Aurore_Evasion"
[[ "$MODE" == "libretest" ]] && MISSION="_SPT_Planet_Libre_Test"
[[ "$MODE" == "jeu" ]] && MISSION="_SPT_Aurore_Evasion_Jeu"
[[ "$MODE" == "jeutest" ]] && MISSION="_SPT_Aurore_Evasion_JeuTest"
[[ -e "$LIBRARY_DIR/SpaceSimPlanet" ]] || ln -s "$PROJECT_DIR/mods/planet" "$LIBRARY_DIR/SpaceSimPlanet"
# FSO on macOS searches mods next to its .app, not in the working directory.
ENGINE_DIR="$PROJECT_DIR/tools/FSO-26.2.0"
for MOD in FotG_R SpaceSimPlanet SpaceSimTerrain; do
  [[ -e "$ENGINE_DIR/$MOD" || ! -e "$LIBRARY_DIR/$MOD" ]] || ln -s "$LIBRARY_DIR/$MOD" "$ENGINE_DIR/$MOD"
done
# A normal launch never inherits test switches left by an interrupted capture/benchmark run.
DATA_USER="$HOME/Library/Application Support/HardLightProductions/FreeSpaceOpen/SpaceSimPlanet/data"
if [[ -z "$SPACESIM_KEEP_FLAGS" && -d "$DATA_USER" ]]; then
  rm -f "$DATA_USER"/spacesim-*.flag(N) "$DATA_USER"/shot_*.b64(N)
fi
cd "$LIBRARY_DIR"
if [[ "$MODE" == "fred" ]]; then
  exec "$PROJECT_DIR/tools/FSO-26.2.0/qtfred_26_2_0_arm64.app/Contents/MacOS/qtfred_26_2_0_arm64" -mod "SpaceSimPlanet,FotG_R/FotG_R-1.1.2" -start_mission "$PROJECT_DIR/mods/planet/data/missions/$MISSION.fs2" -parse_cmdline_only
else
  exec "$PROJECT_DIR/tools/FSO-26.2.0/fs2_open_26_2_0_arm64.app/Contents/MacOS/fs2_open_26_2_0_arm64" -mod "SpaceSimPlanet,FotG_R/FotG_R-1.1.2" -start_mission "$MISSION" -window -res 1440x900 -aa -aa_preset 6 "${SHADOW_FLAGS[@]}" -parse_cmdline_only
fi
