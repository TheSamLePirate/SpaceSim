# Vol de type avion (Aurore)

Script : `mods/planet/data/tables/spacesim-flight-sct.lua`. Il est local au joueur, donc compatible multijoueur.

## Modes (touche **F10**, choix mémorisé dans `data/spacesim-flight.cfg`)

| | Arcade (assisté, par défaut) | Simulation |
|---|---|---|
| Manche latéral (stick gauche X, flèches ←/→) | inclinaison commandée (jusqu'à 72°), virage serré et coordonné | taux de roulis |
| Manche avant / arrière | tangage | tangage, limité par le facteur de charge (7,5 g × portance) |
| Axe ou touches d'inclinaison | roulis libre | palonnier (lacet) |
| Manche relâché | remise à plat et maintien de l'assiette | rien : l'avion garde son attitude |
| Énergie | gravité réduite (55 %), vitesse plancher de 55 m/s | gravité complète, décrochage sous 62 m/s |
| Décrochage | non | perte d'autorité, le nez s'aligne sur l'écoulement puis tombe |

Dans les deux modes :
- **la trajectoire suit le nez** (dérapage amorti en 0,3 s) ;
- **la poussée tend vers la consigne des gaz**, avec les temps d'accélération de la table et au plus 35 m/s² en simulation (60 en arcade) ;
- **gravité radiale** : 9,81 m/s² au sol, en 1/r² ;
- **alarme « REMONTEZ ! »** avec le son FotG de proximité, si le relief est à moins de 25 m sur la trajectoire des 3 prochaines secondes.

## Atmosphère et altitude

- **Effets de l'air** : complets sous 20 km, ils disparaissent entre 20 et 40 km. Au-dessus, c'est le vol FSO normal.
- **Vitesse maximale** : celle de la table près du sol, jusqu'à 4 200 m/s entre 32 et 85 km (montée en orbite jouable), puis retour à la vitesse de combat en orbite.

## Implémentation

- **Commandes** : `ba.setControlMode(FLIGHT_CONTROL_LUA_STEERING)`. Les entrées brutes sont lues (lissées au clavier, avec une courbe à la manette), puis on réécrit tangage, lacet et roulis.
- **Signes calibrés** : `ci.Pitch` positif pique, `ci.Heading` positif tourne à droite, `ci.Bank` positif roule à gauche. L'inclinaison automatique de FSO en lacet est compensée.
- **Translation** : `Physics.Velocity` est réécrite à chaque image dans l'air. FSO la prend telle quelle (`PF_SCRIPTED_VELOCITY`). Les collisions et les ondes de choc sont conservées, car le modèle repart de la vitesse réelle.
- **Inactif** quand la cinématique pilote le joueur, pendant le vol automatique (F8) et pendant la mort.

## Tests

- `MODE=libretest STOP_AT=none scripts/cine_test.sh cal 160 "FLIGHT_MODEL" flightcal` : signes des commandes.
- `MODE=libretest STOP_AT=none scripts/cine_test.sh fly 150 "FLIGHT_MODEL" flighttest` : séquence automatique à +1 200 m (palier, virage, remise à plat, boucle, piqué, décrochage en simulation, roulis).
- `data/spacesim-flightdebug.flag` : télémétrie du vol toutes les 0,5 s.

Mesuré en arcade : virage de 270° en 5 s pour 90 m d'altitude perdus, et retour à plat en 1 s.

## Harnais de test

`scripts/capture_planet.sh` et `scripts/cine_test.sh` :
- **Erreur bloquante** : FSO copie le texte de toute erreur dans le presse-papiers, et le jeu écrit un battement de cœur chaque seconde (`spacesim-heartbeat.txt`). Si les deux concordent, le harnais affiche l'erreur, la sauvegarde dans `artifacts/planet/last-error.txt`, arrête le jeu et sort avec le code 3.
- **Fin de mission** : arrêt immédiat (`spacesim-stop.txt`).
- **Mort ou crash du joueur** : arrêt après `DEATH_HOLD` secondes (6 par défaut).
- **Missions de test sans briefing** : `_SPT_Planet_Libre_Test` (`MODE=libretest`). L'Évasion n'a pas de briefing.
