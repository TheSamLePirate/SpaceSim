#!/bin/zsh
# Usage: bench_raid.sh <label> [profile]  -> canyon and climb FPS (no captures)
cd "${0:A:h:h}"
U="$HOME/Library/Application Support/HardLightProductions/FreeSpaceOpen/SpaceSimPlanet/data"
for seg in ${=SEGS:-raidshort raidclimb}; do
  NOCAPTURE=1 PROFILE=${2:-max} STOP_AT=raid_end scripts/capture_planet.sh "bench_$1_$seg" raid $seg ${=EXTRA} >/dev/null 2>&1
  grep RAID_FPS "$U/spacesim-planet-telemetry.txt" | sed "s/.*RAID_FPS/$1 $seg/" | tee -a artifacts/planet/bench.txt
done
