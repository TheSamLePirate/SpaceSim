# Terrain 01 — preuve technique FSO

Le prototype fonctionne dans **FSO 26.2.0 sur le Mac M1 Max**. Il contient un sol 3D fermé avec collisions, une vallée, des montagnes et le destroyer **Vigilance à 6 000 m de hauteur**. Le vaisseau et le terrain sont présents dès le chargement : le trajet ne change pas de scène.

## Essayer

Dans le Finder, ouvrir le dossier `SpaceSim` et double-cliquer :

- **Terrain - Vol libre.app** : explorer et monter soi-même.
- **Terrain - Demonstration.app** : vol de démonstration et validation automatique, puis commandes libres.
- **Terrain - FRED.app** : inspecter et modifier la mission et le décor.

Au briefing, cliquer **Commit** ou utiliser **Ctrl + Entrée**. Le briefing initial est le seul chargement nécessaire avant le vol. La démonstration prend environ 25 secondes de temps de mission, puis libère les commandes. Le vol libre ne force ni trajectoire ni fin de mission.

Les variantes `.command` exécutent les mêmes lanceurs via Terminal. Utiliser les lanceurs du projet pour que FSO trouve le dossier du mod et les ressources FotG.

Le panneau bleu en haut à gauche affiche :

- **Sol** : distance verticale entre le centre du X-wing et le terrain réel, calculée par un rayon de collision du moteur.
- **Hauteur** : coordonnée verticale dans la mission ; le destroyer est placé à 6 000 m.
- **Contacts sol** : contacts du joueur avec le terrain.
- **Sonde** : résultat du test de collision indépendant.
- **Géométrie 5/5** : cinq sondages sur la géométrie physique du terrain.

Le joueur et la sonde sont invulnérables pour permettre les essais d'impact répétés. Cette invulnérabilité supprime les dégâts, pas la détection ni la réponse physique des collisions. Le prototype n'ajoute pas de gravité.

## Résultat constaté

L'essai enregistré dans `artifacts/terrain/validation-m1max.txt` confirme :

- Terrain présent et cinq intersections de rayons sur sa géométrie.
- Contact physique de la sonde avec le relief : vitesse verticale entrante de **−25 m/s**, puis **−4,28 m/s** après réponse native du moteur sur la pente.
- Sonde encore **9,79 m au-dessus du terrain** à la fin de la démonstration.
- Départ du joueur à **320 m de hauteur**, soit environ **172 m au-dessus du fond de vallée**.
- Ascension au-delà de **5,6 km**, objectif de proximité du destroyer atteint.
- Une seule entrée de mission et aucun repositionnement du joueur par script pendant le trajet. Le pilote automatique modifie seulement vitesse et orientation ; il n'utilise ni téléportation, ni chargement d'une autre scène.
- Vérificateur de QtFRED : **No errors found!**
- Relief et textures visibles depuis le cockpit ; destroyer visible en hauteur.

La vitesse verticale résiduelle de la sonde n'est pas un simple rebond vertical : la surface est inclinée et le moteur transforme également sa trajectoire latérale.

## Environnement et géométrie

- Emprise : **8 × 8 km** ; terrain fini avec bordures.
- Hauteur des sommets : environ **1,4 km** au-dessus du repère de mission.
- Modèle détaillé : **9 794 sommets, 19 584 triangles**.
- Deux niveaux de détail : grilles 96 et 32.
- Volume fermé : surface, parois latérales et dessous ; orientation des faces vérifiée.
- Format POF 2117, polygones texturés et arbre BSP spatial pour les tests de collision.
- Texture originale 1 024 × 1 024, générée avec le relief.

Le relief et la texture sont créés dans ce projet. X-wing, destroyer, cockpit et interface viennent de l'installation de Fate of the Galaxy.

## Installation et isolation

Contenu du prototype : `mods/terrain/data/`.

Le dossier de bibliothèque Knossos contient un lien `SpaceSimTerrain` vers `mods/terrain`. Les lanceurs chargent :

```
-mod SpaceSimTerrain,FotG_R/FotG_R-1.1.2
```

Les ressources du prototype priment sur la dépendance FotG. Aucun fichier du jeu FotG ni la mission Escorte Aurore n'est remplacé.

Le journal de la dernière session est écrit par FSO ici :

```
~/Library/Application Support/HardLightProductions/FreeSpaceOpen/SpaceSimTerrain/data/spacesim-terrain-telemetry.txt
```

La copie de validation conservée dans `artifacts/terrain/` ne change pas quand on rejoue.

## Reproduire les contrôles

Depuis le dossier SpaceSim :

```
python3 scripts/build_terrain.py
python3 scripts/create_terrain_mission.py
scripts/run_terrain.sh auto
```

Après la démonstration, copier le journal de la session vers `artifacts/terrain/validation-m1max.txt`, puis :

```
python3 tests/verify_terrain.py
```

Le contrôle vérifie le maillage fermé, les orientations, les sections du POF, les intersections réelles du moteur comparées aux hauteurs générées, la réponse physique, le maintien de la sonde au-dessus du terrain et l'ascension continue.

**Ne pas relancer le générateur de missions après une édition manuelle dans FRED sans sauvegarder ses modifications** : il réécrit les deux missions du prototype.

## Limites de cette preuve

Ce résultat valide une zone de terrain locale et une montée continue, dans FSO standard. Il ne valide pas encore une planète sphérique, une atmosphère, un terrain infini chargé progressivement ou le comportement à deux joueurs. L'apparence est celle d'un décor technique lunaire sous ciel étoilé.

Le Mac mini M1 n'a pas été utilisé pour cette validation. Le paquet du mod est préparé dans `artifacts/terrain/SpaceSimTerrain-01.tar.gz` pour le prochain essai ; il requiert le moteur 26.2.0 et FotG sur la machine cible.

## Références techniques

Les formats et APIs ont été vérifiés dans les sources officielles 26.2.0 présentes dans `tools/source-26.2.0/` :

- `code/model/modelread.cpp` : lecture des sections POF et BSP.
- `code/model/modelcollide.cpp` : arbre de collision et polygones.
- `code/prop/prop.cpp` : décor POF avec collisions.
- `code/mission/missionparse.cpp` : section `#Props` dans les missions.
- `code/scripting/api/objs/object.cpp` : `checkRayCollision`.
- `code/object/collideshipship.cpp` : réponse physique ship/prop.
- `code/scripting/api/objs/physics_info.cpp` : vitesse scriptée.

Dans cette version, le chemin ship/prop consulte le callback d'override de collision mais n'appelle pas le callback de notification normal. Le script observe le contact dans le premier et **renvoie toujours false**, afin de laisser le moteur appliquer sa physique.
