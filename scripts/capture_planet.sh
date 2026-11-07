#!/bin/zsh
# Automatic sol->orbite run that saves PNG captures in artifacts/planet/shots/<tag>/.
# Usage: scripts/capture_planet.sh <tag> [noair] [noclouds]
set -e
setopt null_glob
PROJECT_DIR="${0:A:h:h}"
# one capture/benchmark at a time: stop any previous run of this script (and its game)
for pid in $(pgrep -f 'scripts/capture_planet[.]sh'); do [[ $pid != $$ ]] && kill $pid 2>/dev/null; done
TIMEOUT="${TIMEOUT:-600}"
U="$HOME/Library/Application Support/HardLightProductions/FreeSpaceOpen/SpaceSimPlanet/data"
mkdir -p "$U"; rm -f "$U"/shot_*.b64 "$U"/spacesim-*.flag
[[ -n "$NOCAPTURE" ]] || touch "$U/spacesim-capture.flag"
for f in "${@:2}"; do touch "$U/spacesim-$f.flag"; done
MODE="${MODE:-auto}"
[[ -n "$ONLY" ]] && print -r -- "$ONLY" > "$U/spacesim-only.flag"
pkill -f fs2_open_26_2_0_arm64 || true; sleep 1
SPACESIM_KEEP_FLAGS=1 "$PROJECT_DIR/scripts/run_planet.sh" "$MODE" "${PROFILE:-qualite}" > "$PROJECT_DIR/artifacts/planet/fso-auto.log" 2>&1 &
LAST="${STOP_AT:-12_orbite}"
for i in $(seq 1 $TIMEOUT); do sleep 1; [[ -f "$U/shot_$LAST.b64" ]] && break; done
sleep 2; pkill -f fs2_open_26_2_0_arm64 || true
rm -f "$U"/spacesim-*.flag
OUT="$PROJECT_DIR/artifacts/planet/shots/$1"; mkdir -p "$OUT"
"$PROJECT_DIR/.venv/bin/python" - "$U" "$OUT" <<'PY'
import base64,io,glob,os,sys
from PIL import Image
for f in sorted(glob.glob(sys.argv[1]+'/shot_*.b64')):
    s=open(f).read().split(',',1)[-1]
    im=Image.open(io.BytesIO(base64.b64decode(s))).convert('RGB')
    im.resize((im.width//2,im.height//2)).save(os.path.join(sys.argv[2],os.path.basename(f)[5:-4]+'.jpg'),quality=85)
PY
grep -E "RESULT" "$U/spacesim-planet-telemetry.txt" || true
ls "$OUT"
