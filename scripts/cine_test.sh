#!/bin/zsh
# Wrapper: run the evasion cinematic with the given flags, wait, print the telemetry lines matching $GREP.
# Usage: cine_test.sh <tag> <seconds> <grep-regex> [flags...]
DIR="${0:A:h}"
TAG=$1; SECS=$2; PAT=$3; shift 3
U="$HOME/Library/Application Support/HardLightProductions/FreeSpaceOpen/SpaceSimPlanet/data"
MODE=${MODE:-evasion} PROFILE=${PROFILE:-qualite} STOP_AT=${STOP_AT:-cine_end} NOCAPTURE=${NOCAPTURE-1} TIMEOUT=$SECS "$DIR/capture_planet.sh" "$TAG" "$@" > /tmp/cine_test.log 2>&1
RC=$?
if [[ $RC == 3 ]]; then cat /tmp/cine_test.log; exit 3; fi
grep "^STOP" /tmp/cine_test.log
grep -E "$PAT" "$U/spacesim-planet-telemetry.txt" 2>/dev/null | cut -c14-260
