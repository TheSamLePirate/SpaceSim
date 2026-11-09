#!/usr/bin/env bash
# Rebuilds the whole "Aurore 03" planet mod (mods/planet) from the sources in git.
#
#   scripts/build_all.sh                  full rebuild (~ several minutes, ~2.6 GB written)
#   scripts/build_all.sh --assets-only    only the generated models/maps (git-ignored); missions,
#                                         tables and shaders in git are left untouched
#   scripts/build_all.sh --quality high   shader quality: low | high | ultra (default: ultra)
#   scripts/build_all.sh --from tiles     resume from a step (see STEPS below)
#
# What it does:
#   1. creates .venv/ and installs requirements.txt (numpy, pillow) if needed;
#   2. fetches the official FSO 26.2.0 shader sources into tools/source-26.2.0 if needed
#      (sparse git clone, only code/def_files/data/effects + licences; used by the shader step);
#   3. runs every generator in dependency order.
#
# A full rebuild rewrites files tracked by git (missions, spacesim-prp.tbm / spacesim-mod.tbm,
# effects/*.sdr, artifacts/planet/*.json and previews): check them with `git diff` afterwards.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VENV="$ROOT/.venv"
SRC="$ROOT/tools/source-26.2.0"
FSO_REPO="https://github.com/scp-fs2open/fs2open.github.com.git"
FSO_TAG="release_26_2_0"

ASSETS_ONLY=0
QUALITY="ultra"
FROM=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --assets-only) ASSETS_ONLY=1 ;;
    --quality) QUALITY="$2"; shift ;;
    --from) FROM="$2"; shift ;;
    -h|--help) sed -n 2,16p "$0"; exit 0 ;;
    *) echo "Unknown option: $1 (see --help)"; exit 1 ;;
  esac
  shift
done
[[ "$QUALITY" =~ ^(low|high|ultra)$ ]] || { echo "--quality must be low, high or ultra"; exit 1; }

# ---- 1. Python environment ---------------------------------------------------------------
if [[ ! -x "$VENV/bin/python" ]]; then
  PY="${PYTHON:-python3}"
  "$PY" -c 'import sys; sys.exit(sys.version_info < (3, 10))' \
    || { echo "Python 3.10+ required (set PYTHON=/path/to/python3)"; exit 1; }
  echo "==> Creating $VENV"
  "$PY" -m venv "$VENV"
fi
PYTHON="$VENV/bin/python"
if ! "$PYTHON" -c 'import numpy, PIL' 2>/dev/null; then
  echo "==> Installing requirements.txt"
  "$PYTHON" -m pip install --quiet --upgrade pip
  "$PYTHON" -m pip install --quiet -r "$ROOT/requirements.txt"
fi

# ---- 2. FSO 26.2.0 shader sources (shader step only) ---------------------------------------
fetch_fso_source() {
  if [[ -f "$SRC/code/def_files/data/effects/main-f.sdr" && -f "$SRC/Copying.md" ]]; then return; fi
  if [[ -e "$SRC" ]]; then
    echo "$SRC exists but is incomplete (no code/def_files/data/effects/main-f.sdr): remove it and retry."
    exit 1
  fi
  command -v git >/dev/null || { echo "git is required to fetch the FSO sources"; exit 1; }
  echo "==> Fetching FSO $FSO_TAG shader sources into $SRC"
  local tmp; tmp="$(mktemp -d)"
  git clone --quiet --depth 1 --branch "$FSO_TAG" --filter=blob:none --sparse "$FSO_REPO" "$tmp/src"
  git -C "$tmp/src" sparse-checkout set code/def_files/data/effects   # cone mode also keeps root files
  mkdir -p "$(dirname "$SRC")"
  mv "$tmp/src" "$SRC"
  rm -rf "$tmp"
}

# ---- 3. Generators, in dependency order ----------------------------------------------------
# name | command (run from scripts/) | tracked = rewrites files in git
STEPS=(
  "planet|build_planet.py|0"                                            # ss_p_* face textures, sky, atmosphere shells 0-2
  "clouds|build_planet_clouds.py|0"                                     # ss_c_* cloud shells (historical layer)
  "noise|build_cloud_noise.py|0"                                        # 3D noise atlas ss_air-trans-misc (clouds, forest/rock masks)
  "tiles|build_planet_tiles.py --depth 8 --cells 192|0"                 # terrain tiles + collisions -> artifacts/planet/tiles.json
  "heightmap|build_planet_heightmap.py|0"                               # spacesim-height.txt (Lua altitude lookups), needs tiles.json
  "atmosphere|build_planet_atmosphere.py|0"                             # single atmosphere mesh ss_atmo_0 (replaces planet's)
  "ground|build_planet_ground.py|0"                                     # outpost, turbolaser towers, AT-ATs, rocks -> ground.json
  "vegetation|build_planet_vegetation.py --spacing 9 --density 1.3 --boxes|0"  # forest sectors -> vegetation.json
  "deathstar|build_death_star.py|0"                                     # Death Star model and textures
  "cine|build_cine_assets.py|0"                                         # planet core, fragments, glow sprites (cinematic)
  "missions|create_planet_mission.py|1"                                 # all planet missions + spacesim-prp/mod.tbm
  "shader|build_planet_shader.py --quality $QUALITY|1"                  # effects/*.sdr (atmosphere, clouds, materials)
)

if [[ -n "$FROM" ]] && ! printf '%s\n' "${STEPS[@]}" | cut -d'|' -f1 | grep -qx "$FROM"; then
  echo "Unknown step for --from: $FROM. Steps: $(printf '%s\n' "${STEPS[@]}" | cut -d'|' -f1 | tr '\n' ' ')"
  exit 1
fi

mkdir -p "$ROOT/mods/planet/data/"{models,maps,missions,tables,effects} "$ROOT/artifacts/planet"
cd "$ROOT/scripts"
started=$([[ -z "$FROM" ]] && echo 1 || echo 0)
total_start=$SECONDS
for step in "${STEPS[@]}"; do
  IFS='|' read -r name cmd tracked <<<"$step"
  [[ "$name" == "$FROM" ]] && started=1
  [[ "$started" == 1 ]] || continue
  if [[ "$ASSETS_ONLY" == 1 && "$tracked" == 1 ]]; then
    echo "==> [$name] skipped (--assets-only)"; continue
  fi
  [[ "$name" == "shader" ]] && fetch_fso_source
  echo "==> [$name] $cmd"
  t=$SECONDS
  # shellcheck disable=SC2086
  "$PYTHON" $cmd
  echo "    [$name] done in $((SECONDS - t)) s"
done

echo "==> Build complete in $((SECONDS - total_start)) s: $ROOT/mods/planet"
[[ "$ASSETS_ONLY" == 1 ]] || echo "    Tracked files may have changed: review with 'git status' / 'git diff'."
