#!/bin/zsh
# Aurore - Evasion, mission jouable (solo) : briefing, decollage, canyon, montee en orbite, Etoile Noire.
# F10 : vol Arcade / Simulation. Espace : passer l'intro. Qualite max (Vulkan, ombres).
PROJECT_DIR="${0:A:h}"
exec "$PROJECT_DIR/scripts/run_planet.sh" jeu max
