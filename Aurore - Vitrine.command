#!/bin/zsh
# Automatic showcase: 17 cinematic shots (time of day, outpost, turrets, orbit).
# Images are written to artifacts/planet/shots/vitrine/.
PROJECT_DIR="${0:A:h}"
PROFILE=max STOP_AT=g06_foret exec "$PROJECT_DIR/scripts/capture_planet.sh" vitrine showcase
