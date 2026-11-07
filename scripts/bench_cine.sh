#!/bin/zsh
# Usage: bench_cine.sh <label> [flags...]  -> canyon FPS of the evasion cinematic (profile max, no captures)
cd "${0:A:h:h}"
U="$HOME/Library/Application Support/HardLightProductions/FreeSpaceOpen/SpaceSimPlanet/data"
PROFILE=${PROFILE:-max} scripts/cine_test.sh "bench_$1" 420 "x^" cinecanyon "${@:2}" || exit $?
L=$(grep -E "CINE FPS phase=(canyon|camp)" "$U/spacesim-planet-telemetry.txt" | sed 's/.*CINE FPS //' | tr '\n' ' ')
print -r -- "$(date +%H:%M) $1 ${PROFILE:-max} $L" | tee -a artifacts/planet/bench.txt
