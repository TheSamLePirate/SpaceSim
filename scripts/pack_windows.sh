#!/bin/zsh
# Builds artifacts/SpaceSim-Windows.zip: the generated planet mod (mods/planet, ~2.6 GB, not in git)
# renamed SpaceSimPlanet, plus the Windows launchers. Unzip it into the friend's Knossos library.
set -e
PROJECT_DIR="${0:A:h:h}"
OUT="$PROJECT_DIR/artifacts/SpaceSim-Windows.zip"
[[ -d "$PROJECT_DIR/mods/planet/data/models" ]] || { echo "mods/planet/data/models missing: rebuild the planet first (docs/AURORE-03.md)"; exit 1; }
STAGE=$(mktemp -d)
trap 'rm -rf "$STAGE"' EXIT
ln -s "$PROJECT_DIR/mods/planet" "$STAGE/SpaceSimPlanet"
cp "$PROJECT_DIR"/windows/*.bat "$PROJECT_DIR/windows/LISEZMOI-WINDOWS.txt" "$STAGE/"
rm -f "$OUT"
cd "$STAGE"
# zip follows symlinks by default; test outputs and flags are left out
zip -r -q "$OUT" . -x "*.DS_Store" "*/spacesim-*.flag" "*/shot_*.b64"
ls -lh "$OUT"
