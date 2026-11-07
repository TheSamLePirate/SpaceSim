#!/bin/zsh
# Scripted one-shot scene, maximum quality: sunset canyon run under turbolaser fire, climb to
# orbit, attack on the Star Destroyer, jump to lightspeed from the cockpit. FPS shown top right.
PROJECT_DIR="${0:A:h}"
NOCAPTURE=1 PROFILE=max STOP_AT=raid_end exec "$PROJECT_DIR/scripts/capture_planet.sh" raid raid
