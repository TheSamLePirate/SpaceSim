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
# FSO copies the text of every Lua error / Error / Warning dialog to the clipboard before showing it
# (osapi/dialogs.cpp): watch it, so a blocked game is reported instead of waiting for the timeout.
CLIP0="$(pbpaste 2>/dev/null | shasum)"
ERRFILE="$PROJECT_DIR/artifacts/planet/last-error.txt"; rm -f "$ERRFILE" "$U/spacesim-heartbeat.txt" "$U/spacesim-stop.txt"; DEADLINE=""
# never read a previous run: the telemetry of this run only
rm -f "$U/spacesim-planet-telemetry.txt"
for i in $(seq 1 $TIMEOUT); do
  sleep 1; [[ -f "$U/shot_$LAST.b64" ]] && break
  # the game process died (crash): report it with the macOS crash report
  if (( i > 5 )) && ! pgrep -f fs2_open_26_2_0_arm64 >/dev/null; then
    REP=$(ls -t ~/Library/Logs/DiagnosticReports/fs2_open*.ips 2>/dev/null | head -1)
    print -r -- "FSO_CRASH (le jeu s'est arrete) : $REP"
    [[ -n "$REP" ]] && "$PROJECT_DIR/.venv/bin/python" - "$REP" <<'PYC' | tee "$ERRFILE"
import json,sys
t=open(sys.argv[1]).read().split('\n',1);d=json.loads(t[1])
print(d.get('exception',{}).get('type'),d.get('exception',{}).get('signal'))
th=[x for x in d['threads'] if x.get('triggered')][0]
for f in th['frames'][:8]: print('  ',d['usedImages'][f['imageIndex']].get('name','?'),f.get('symbol','?'))
PYC
    rm -f "$U"/spacesim-*.flag; exit 4
  fi
  # the game reports the end of the mission / the death of the player (spacesim-planet-sct.lua, stopSignal)
  if [[ -f "$U/spacesim-stop.txt" ]]; then
    REASON="$(cut -d' ' -f1 "$U/spacesim-stop.txt")"
    if [[ "$REASON" == mission_end ]]; then print -r -- "STOP: fin de mission"; break; fi
    [[ -z "$DEADLINE" ]] && DEADLINE=$(( i + ${DEATH_HOLD:-6} )) && print -r -- "STOP: $REASON (arret dans ${DEATH_HOLD:-6} s)"
    (( i >= DEADLINE )) && break
  fi
  if [[ "$(pbpaste 2>/dev/null | shasum)" != "$CLIP0" ]]; then
    CLIP="$(pbpaste 2>/dev/null)"
    HBF="$U/spacesim-heartbeat.txt"
    AGE=$(( $(date +%s) - $(stat -f %m "$HBF" 2>/dev/null || echo 0) ))
    # a real dialog blocks the game: its heartbeat (rewritten every second) stops; no heartbeat yet = loading
    if print -r -- "$CLIP" | grep -q -E "LUA ERROR|stack traceback|Argument [0-9]|Error:|Warning:|Assert" && (( AGE >= 3 )); then
      print -r -- "$CLIP" > "$ERRFILE"
      print -r -- "FSO_ERROR (dialogue bloquant, jeu arrete) :"; print -r -- "$CLIP" | head -30
      pkill -f fs2_open_26_2_0_arm64 || true; rm -f "$U"/spacesim-*.flag
      exit 3
    fi
  fi
done
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
