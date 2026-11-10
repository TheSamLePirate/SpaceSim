#!/bin/zsh
# Usage: mem_probe.sh <mode> [profile] [seconds] -> total RSS of ALL FSO instances every 2 s, mission time, peak.
# Only one instance: the previous ones are stopped (and waited for) first. Safety stop above 22 GB.
cd "${0:A:h:h}"
U="$HOME/Library/Application Support/HardLightProductions/FreeSpaceOpen/SpaceSimPlanet/data"
scripts/fso_stop.sh || exit 1
rm -f "$U/spacesim-heartbeat.txt"
SPACESIM_KEEP_FLAGS=1 scripts/run_planet.sh "$1" "${2:-rapide}" > /tmp/mem_probe.log 2>&1 &
PK=0
for i in $(seq 1 $(( ${3:-60} / 2 ))); do
  sleep 2
  N=$(pgrep -f fs2_open_26_2_0_arm64 | wc -l | tr -d ' ')
  (( N == 0 )) && { echo "jeu ferme"; break; }
  M=$(ps -o rss= -p $(pgrep -f fs2_open_26_2_0_arm64 | tr '\n' ',' | sed 's/,$//') | awk '{s+=$1} END {print int(s/1024)}')
  (( M > PK )) && PK=$M
  HB=$(cat "$U/spacesim-heartbeat.txt" 2>/dev/null)
  echo "$((i*2))s instances=$N rss=${M}MB mission_t=${HB:-chargement}"
  (( M > 22000 )) && { echo "ARRET SECURITE"; break; }
done
echo "pic=${PK}MB"
scripts/fso_stop.sh
