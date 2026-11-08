# Aurore – Évasion : plan de production

Mission jouable FSO 26.2 + Fate of the Galaxy 1.1.2, en solo et en coop jusqu'à 4 joueurs en réseau.
Le cargo GR-75 *Aurore* fuit par le canyon, monte en orbite et saute en hyperespace avant que l'Étoile
Noire ne détruise la planète. L'escadron Rouge (4 X-wing) l'escorte.

## Décisions validées (07/11)

| Sujet | Décision |
|---|---|
| Ouverture | la cinématique de décollage est conservée, puis le joueur prend les commandes |
| Montée en orbite | jouable : la vitesse maximale augmente avec l'altitude (environ 45 s pour 110 km) |
| Vol | type avion, deux modes au choix (**Arcade** assisté / **Simulation**), manette X360 et clavier |
| Vaisseaux | X-wing T-65 uniquement |
| Mort | réapparition (option FotG « Player Respawns » en solo, réapparitions coop en multi), au-dessus du cargo |
| Batteries | objectif d'équipe |
| TIE | présents dès le canyon |
| Dialogues | texte français uniquement |

## Principes

- **Ne rien modifier dans FSO ni dans FotG** : tout passe par `mods/planet` (tables `.tbm`, scripts Lua, modèles générés).
- **Compatible réseau dès la conception** :
  - les vaisseaux et les armes viennent de la mission (arrivées, SEXP synchronisées, `firePrimary`) ;
  - jamais de `createShip` ni de `createWeapon` en jeu (ils ne sont pas transmis) ;
  - la logique de jeu tourne sur le serveur, les caméras et les effets visuels chez chaque joueur.
- **Les cibles sont de vrais vaisseaux** : sur le radar, verrouillables, détruites par de vrais dégâts.
- **Chaque chantier est mesuré** : banc de test automatique, télémétrie, FPS par phase.
- **Qualité « AAA » d'abord**, puis optimisation sans perte visible.

## Phase 1 – Fondations solo

| # | Tâche | Critère de réussite |
|---|---|---|
| 1.1 | **Carte d'altitude** exportée par la génération du terrain, lue en Lua (`SPACESIM.ground`) | hauteur sol en O(1), écart avec le maillage de collision : 0,4 m en moyenne, 4,6 m au pire (mesuré) ; lancer de rayon en secours hors carte |
| 1.2 | **Vol de type avion** (`spacesim-flight-sct.lua`), dosé par la densité de l'air | roulis → virage coordonné, énergie (montée et piqué), décrochage en mode Simulation, assistance en mode Arcade, transition vers le vol spatial entre 20 et 40 km |
| 1.3 | Manette X360 et clavier | commandes numériques lissées au clavier, zone morte et courbe à la manette, bascule de mode (F10) avec affichage sur le HUD |
| 1.4 | **Alarme de proximité du sol** | « REMONTEZ » sur le HUD plus un son, anticipé d'après la vitesse verticale |
| 1.5 | Nettoyage de la mission | plus de joueur invulnérable, ni de sonde, ni de *Vigilance* ; balises invisibles au radar et au ciblage |
| 1.6 | **IA qui évite le relief** (serveur) : TIE, ailiers, tous les chasseurs IA près du sol | aucun crash IA sur 3 parties du canyon |
| 1.7 | **Réapparition** au-dessus du cargo (FotG Respawner en solo, réapparition multi) | jamais dans la roche, invulnérable 3 s |

## Phase 2 – Performances (objectif : 25 à 30 FPS au canyon avec les ombres, contre 19 en profil max)

Coûts mesurés : ombres ≈ 17 ms par image, entités FotG au sol ≈ 9 ms, végétation, Lua de 1 à 4 ms.

| # | Piste | Mesure |
|---|---|---|
| 2.1 | Distances des cascades d'ombre (`120/420/1500/5000`) | FPS et captures avant/après |
| 2.2 | Detail boxes de la végétation (prises en compte par le calcul des ombres en 26.2) | FPS |
| 2.3 | Cibles qui apparaissent avec la progression du cargo (arrivées de mission, compatible multi) | FPS |
| 2.4 | Distances de LOD des forêts et des rochers | FPS et captures |
| 2.5 | Lua : la carte d'altitude remplace les lancers de rayon | ms par image |

## Phase 3 – La mission jouable (solo)

1. **Cinématique de décollage**, que l'on peut passer. Puis transition (coupe vers le cockpit) et prise de commandes à l'entrée du canyon.
2. **Canyon**, environ 10 km. Le cargo accélère.
   - Objectif d'équipe : 10 batteries, avec un compteur dans les directives.
   - Les bâtiments et les AT-AT sont des cibles secondaires.
   - Des TIE en patrouille dès le début.
3. **Montée en orbite** : la vitesse maximale augmente avec l'altitude, et le cargo est escorté par les joueurs.
4. **Orbite** : 3 destroyers stellaires arrivent par l'hyperespace et lancent leurs TIE. Objectif secondaire : torpiller un destroyer.
5. **Étoile Noire** : lever d'astre, superlaser, puis destruction de la planète. Le cargo saute, et les joueurs doivent sauter avant l'onde de choc.
6. **Fin** : débriefing selon les objectifs.

Échec si l'*Aurore* est détruite. Sous-titres en français et messages FotG (texte seulement).

## Phase 4 – Coop en réseau, 4 joueurs

| Système | Version réseau |
|---|---|
| Mission | `_MPC_Aurore_Evasion.fs2` : type coop, 4 joueurs, aile « Rouge » de départ, réapparitions, places libres pilotées par l'IA |
| Cargo | déplacé par le serveur seulement (positions transmises par le moteur) |
| Ennemis | arrivées de mission (hyperespace, hangar), aucune création Lua |
| Tirs IA | IA FSO, ou `firePrimary` / `fireSecondary` exécutés sur le serveur |
| Crash, objectifs, événements | serveur seulement (`multi.isServer()`) |
| Caméras de la cinématique | chez chaque joueur, à partir des positions synchronisées (le script qui dirige est séparé de celui qui filme) |
| Vol avion | chez chaque joueur, sur son propre vaisseau |
| Étoile Noire et fragments | props locaux, tirage aléatoire identique, sans collision |
| Réapparition | le joueur concerné se replace lui-même au-dessus du cargo |

## Phase 5 – Contenu

**Vie au sol**
- Colonnes de fumée persistantes sur les cibles détruites.
- Rivière au fond du canyon.
- Oiseaux.
- Poussière au ras du sol.

**Scénario**
- D'autres vaisseaux rebelles décollent avec le cargo.
- Un Gozanti dépose des AT-AT qui marchent.
- Un destroyer bombarde la vallée.
- Objectif secondaire : détruire la tour de communication à temps, sinon des renforts TIE arrivent.
- Objectif secondaire : la navette Lambda tente de fuir.

**Points de repère**
- Ponts, épaves, cheminées de l'avant-poste.

## Phase 6 – Qualité et livraison

- **Bancs automatiques** :
  - armes (`cinetest`) ;
  - crash (`cinecrash`) ;
  - vol (`flighttest`) ;
  - canyon complet ;
  - cinématique complète.
- **Planches de captures** à chaque étape.
- **Lanceurs `.command`** et documentation (`docs/AURORE-03.md`, ce plan).

## Suivi

| Phase | État |
|---|---|
| 0 – dépôt git, plan | fait |
| 1 – fondations solo | **fait** : 1.1 carte d'altitude ✅, 1.2-1.4 vol avion, manette, alarme ✅ (réglage fin à faire avec tes retours), 1.5 nettoyage ✅, 1.6 IA et relief ✅ (banc aitest : 0/4 → 4/4), 1.7 réapparition ✅ (FotG Respawner forcé, au-dessus de l'Aurore, protection 3 s) |
| 2 – performances | **fait** : Vulkan par défaut (canyon 14,5 → 26,5–30,8 FPS avec ombres), végétation en detail boxes, diagnostic complet dans AURORE-03.md |
| 3 – mission jouable | **fait** (solo) : voir « Phase 3 – état » |
| 4 – coop en réseau | **fait** (architecture, mission `_MPC_`, non testé en réseau réel) |
| 5 – contenu | **fait** (escortes rebelles, Lueur abattue, fumées, tour de communication et renforts, fuite de la navette) |
| 6 – qualité | en cours |

## Phase 3 – état (07/11)

Missions générées par `create_planet_mission.py` :

| Mission | Rôle | Lancement |
|---|---|---|
| `_SPT_Aurore_Evasion.fs2` | cinématique complète, sans briefing | `run_planet.sh evasion` |
| `_SPT_Aurore_Evasion_Jeu.fs2` | **mission jouable**, avec briefing | `run_planet.sh jeu` |
| `_SPT_Aurore_Evasion_JeuTest.fs2` | copie de test, sans briefing | `MODE=jeutest` ; avec `jeubot`, le joueur est piloté par le script |

**Déroulement**
1. Intro de 10 s (Espace, Entrée ou Échap pour la passer), puis coupe vers le cockpit et prise de commandes : joueur aligné sur le canyon, gaz à 75 %.
2. **Canyon, environ 130 s**.
   - Le cargo accélère de 40 à 160 m/s.
   - Les ailiers IA attaquent la cible vivante la plus proche devant le cargo, une cible par ailier.
   - Patrouilles TIE : 3 chasseurs à T+6 s, puis 2 chasseurs et 1 intercepteur à mi-canyon.
   - Affichage : `BATTERIES x / 10` et `AURORE coque %`.
3. **Montée, environ 75 s** : le cargo est plafonné à 80 % de l'enveloppe de vitesse des joueurs et les ailiers le gardent.
4. **Orbite** : destroyers et TIE, puis l'Étoile Noire.
5. **Destruction** : saut autorisé (« SAUT HYPERSPATIAL : MAINTENANT ! »), plus de réapparition. Le joueur qui ne saute pas 26 s après l'impact est emporté par l'onde de choc.
6. **Débriefing en 4 cas** : succès complet, cargo sauvé mais batteries restantes, cargo perdu, saut manqué.

**Équilibrage**
- **Cargo** : il prend 15 à 55 % des dégâts selon la difficulté FotG, et au plus 8 % de coque par seconde. Il peut être détruit, ce qui fait échouer la mission (fin 9 s plus tard).
- **Bot et ailiers IA** : les 10 batteries sont détruites en 2 parties sur 3, et le cargo finit entre 74 et 99 %.

**Mesures (Vulkan, profil qualité, mission complète avec le bot)**

| Phase | FPS |
|---|---|
| Canyon | 22 |
| Montée | 73 |
| Orbite | 104 |
| Destruction | 83 |

**Sous Vulkan, plus aucun `mn.createExplosion` dans nos scripts** : il plantait le jeu (deux crashs analysés). À la place, `SPACESIM.boom` produit des particules animées avec la même texture, plus le son d'explosion.

**Reste pour la phase 4** : les destroyers, les TIE et les patrouilles sont encore créés en Lua (`createShip`). Ils passeront en arrivées de mission, ce qui est obligatoire en réseau.

## Phase 4 – coop en réseau : architecture (07/11)

Mission `_MPC_Aurore_Evasion.fs2` :
- coop, **4 joueurs**, 30 réapparitions ;
- aile de départ « Rouge » (Rouge 1 à 4, toutes `player-start`), les places libres étant pilotées par l'IA ;
- l'*Aurore* est le point de réapparition (`Respawn priority 100`) ;
- réserve de 4 X-wing, 8 KX-9 et 24 MG7.

**Ce qui passe par le moteur (synchronisé)**
- **Arrivées de mission**, déclenchées par le SEXP Lua `spacesim-phase-reached` (`spacesim-sexp.tbm`), évalué sur le serveur :
  - Patrouille Noire et Patrouille Grise dans le canyon, sans effet de saut ;
  - destroyers Chimère, Tyran et Vengeance (hyperespace) ;
  - leurs escadrilles de TIE, lancées depuis les hangars (`Docking Bay`).
- **Points d'arrivée** écrits dans les parse objects par `CINE.placeArrivals`. Ils sont calculés de la même façon sur toutes les machines, à partir du trajet déterministe du cargo.
- **Positions des vaisseaux pilotés par le serveur** : le cargo, les ailiers IA, et l'IA qui évite le relief.
- **Morts et dégâts** : la mort au contact du sol est décidée par le serveur. En multi, pas de témoin local : un `kill` simple.
- **Ordres IA** (`giveOrder`) donnés sur le serveur, tirs IA natifs, fin de mission (`end-mission`) envoyée par le serveur.

**Ce que chaque client calcule lui-même (directeur en « miroir »)**
- **Avancement du cargo** : projection de sa position synchronisée sur le trajet (`CINE.projectS`). Il en tire les mêmes phases, la même chronologie de l'Étoile Noire, les mêmes sous-titres et la même destruction de la planète. Les fragments sont créés en même nombre sur chaque machine.
- **Caméras de l'intro, HUD et sous-titres.**
- **Son propre vaisseau** :
  - pendant l'intro, positionné par son client ;
  - après la passation, le vol avion (`spacesim-flight-sct.lua`) ;
  - l'autorisation de saut (`never-warp` sur son vaisseau) ;
  - la réapparition FSO : il se replace au-dessus de l'*Aurore* (`MP_RESPAWN`).

**Désactivé en multijoueur**
- Le chargement à la volée des entités (`vanish` / `createShip` impossibles) : toutes les cibles restent actives, au prix de quelques FPS.
- Le saut de l'intro.
- Le Respawner FotG (solo seulement).
- La mort mise en scène de la cinématique et le bot de test.

**Reste en `createShip` / `createWeapon` : la cinématique seule** (`_SPT_Aurore_Evasion`, solo). Les missions jouables n'en utilisent plus.

**Pièges rencontrés**
- `mn.Ships['absent']` renvoie un handle **invalide mais vrai**. Il faut toujours tester avec `isValid()`.
- Une aile de départ impose :
  - un sous-système `Pilot` dans chaque bloc de vaisseau ;
  - des réserves de vaisseaux et d'armes pour toutes ses places (sinon : « Player must select a place in player wing ») ;
  - la même première aile en « team versus team ».

**Non testé en réseau réel** (comme convenu) : les mécanismes sont ceux que FSO synchronise nativement. La partie solo de chaque chemin de code est validée par les bancs automatiques.

## Phase 5 – contenu ajouté (07/11)

**Toutes les missions**
- Le **Faucon de Brume** (YT-1300) et la **Lueur** (GR-75) décollent avec l'*Aurore* et la suivent, pilotés par le serveur.
- La *Lueur* est **abattue dans le canyon**, avec des sous-titres. Le Faucon saute avec l'*Aurore*.
- **Colonnes de fumée et feux** au sol, pendant 5 min, au-dessus des cibles détruites. C'est un effet local à chaque machine, avec les textures FotG `ParticleSmoke01` et `ss_glow_fire`, limité à 9 km de la caméra.

**Mission jouable : objectifs secondaires**
- **Tour de communication** : si elle est encore debout quand l'*Aurore* la dépasse, l'aile **Renforts** (4 intercepteurs) arrive (SEXP `spacesim-flag "renforts"`).
- **Navette Lambda** : elle décolle de l'avant-poste à l'approche du cargo et monte vers l'orbite. Elle saute en hyperespace au-dessus de 9 km si personne ne l'abat.
- Les vaisseaux pilotés par le directeur sont exclus de l'évitement IA et du chargement à la volée.

**Idées restantes** (non faites)
- Rivière au fond du canyon, oiseaux, poussière au ras du sol.
- Gozanti déposant des AT-AT qui marchent.
- Bombardement depuis l'orbite.
