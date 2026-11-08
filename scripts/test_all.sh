#!/bin/zsh
# Aurore - regression suite: every automated bench, with a pass criterion. About 25 minutes.
# Usage: scripts/test_all.sh [names...]   (default: all)   -> summary in artifacts/planet/test_all.txt
cd "${0:A:h:h}"
U="$HOME/Library/Application Support/HardLightProductions/FreeSpaceOpen/SpaceSimPlanet/data"
OUT=artifacts/planet/test_all.txt; : > $OUT
typeset -A ENV ARGS CHECK
# name           env                                        flags                      pass criterion (grep -E on the telemetry)
ENV[hauteur]="STOP_AT=none";        ARGS[hauteur]="hmtest cinecanyon";  CHECK[hauteur]="HMTEST samples=600 mean_err=0\."
ENV[armes]="";                      ARGS[armes]="cinecanyon cinetest";  CHECK[armes]="WTEST RESULT Batterie 10 .*final=DESTROYED"
ENV[cinematique]="";                ARGS[cinematique]="cinecanyon";     CHECK[cinematique]="TARGETS destroyed=23/23"
ENV[crash]="DEATH_HOLD=30";         ARGS[crash]="cinecanyon cinecrash"; CHECK[crash]="PLAYER_DEATH"
ENV[vol]="MODE=libretest STOP_AT=none";      ARGS[vol]="flighttest";     CHECK[vol]="TEST done"
ENV[ia]="MODE=libretest STOP_AT=none";       ARGS[ia]="aitest";          CHECK[ia]="AITEST RESULT survivors=4/4"
ENV[reapparition]="MODE=libretest STOP_AT=none DEATH_HOLD=8"; ARGS[reapparition]="respawntest"; CHECK[reapparition]="RESPAWN Red 1 at"
ENV[jeu]="MODE=jeutest PROFILE=rapide";      ARGS[jeu]="jeubot";         CHECK[jeu]="JUMP player"
ORDER=(hauteur armes cinematique crash vol ia reapparition jeu)
(( $# )) && ORDER=($@)
FAIL=0
for t in $ORDER; do
  T0=$(date +%s)
  env ${=ENV[$t]} scripts/cine_test.sh "test_$t" 1000 "x^" ${=ARGS[$t]} > /tmp/test_$t.log 2>&1; RC=$?
  if (( RC == 0 )) && grep -q -E "${CHECK[$t]}" "$U/spacesim-planet-telemetry.txt" 2>/dev/null; then R=OK; else R="ECHEC (rc=$RC)"; FAIL=1; fi
  [[ $t == jeu ]] && grep -q "FAILED cargo" "$U/spacesim-planet-telemetry.txt" && { R="ECHEC (cargo perdu)"; FAIL=1 }
  print -r -- "$(printf '%-14s' $t) $R  ($(( $(date +%s)-T0 )) s)" | tee -a $OUT
  (( RC == 3 || RC == 4 )) && grep -v "\.jpg$" /tmp/test_$t.log | head -12 | tee -a $OUT
done
exit $FAIL
