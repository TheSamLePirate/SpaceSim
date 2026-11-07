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
| 1 – fondations solo | en cours : 1.1 carte d'altitude ✅, 1.2-1.4 vol avion, manette, alarme ✅ (réglage fin à faire avec tes retours), 1.5 nettoyage ✅, 1.6 IA et relief ⏳, 1.7 réapparition ⏳ |
| 2 – performances | à faire |
| 3 – mission jouable | à faire |
| 4 – coop en réseau | à faire |
| 5 – contenu | à faire |
| 6 – qualité | à faire |
