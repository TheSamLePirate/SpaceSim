#!/bin/zsh
# Aurore - Evasion en cooperation (jusqu'a 4 joueurs) : le jeu s'ouvre sur le menu principal.
# Multijoueur -> Heberger une partie -> "[Rebel] Aurore - Evasion (coop)". Chaque joueur doit avoir le meme
# mod (dossier mods/planet + FotG 1.1.2). Les places libres sont pilotees par l'IA.
PROJECT_DIR="${0:A:h}"
exec "$PROJECT_DIR/scripts/run_planet.sh" menu max
