<a id="english"></a>

# SpaceSim — FSO prototypes

**English** · [Français](#francais)

## Aurore – Escape (playable mission, solo and co-op up to 4 players)

The rebel freighter *Aurore* flees through a canyon under Imperial fire, climbs to orbit, then has to jump to hyperspace before the Death Star destroys the planet. Red Squadron escorts it in X-wings.

![Full raid: canyon at sunrise, climb through the clouds, attack in orbit against the Star Destroyer, then the jump to hyperspace](artifacts/planet/aurore03-raid-aaa.jpg)

*The raid from start to finish: canyon run, climb through the clouds, orbital fight against the Star Destroyer, hyperspace jump.*

| Launcher | What it does |
|---|---|
| **Aurore - Evasion.command** | playable mission (solo), with briefing and debriefing |
| **Aurore - Evasion coop.command** | game menu: Multiplayer → Host → "[Rebel] Aurore - Evasion (coop)" |
| **Aurore - Evasion (cinematique).command** | the full cinematic |

**In game**
- **F10**: Arcade (assisted) or Simulation flight.
- **Space**: skip the intro.
- **Objectives**: destroy the 10 canyon batteries (as a team), protect the *Aurore*, then jump when ordered.
- **Secondary objectives**: the communications tower (otherwise reinforcements arrive) and the escaping shuttle.

**Documentation** (in French)
- Plan and status of each phase: [docs/PLAN-AURORE-EVASION.md](docs/PLAN-AURORE-EVASION.md).
- Aircraft-style flight: [docs/VOL-AVION.md](docs/VOL-AVION.md).
- Rendering, performance, weapons and crashes: [docs/AURORE-03.md](docs/AURORE-03.md).

**Automated tests**: `scripts/test_all.sh` (about 25 min). It covers the heightmap, weapons, cinematic, crashes, flight, AI, respawn and the full mission.

First mission for **Fate of the Galaxy 1.1.2**, built with its existing assets.

## Aurore 03: "AAA" planet, atmosphere and clouds

A 160 km planet you can fly over from the ground to orbit, with no loading screen. It has a physically based atmosphere with real sunsets, volumetric clouds, and an Imperial outpost with firing turbolaser towers, AT-ATs, forests and rocks.

- **Aurore - Vol libre.app** / **Aurore - Sol vers orbite.app**: game (F8 autopilot route, F9 speed, F7 time of day, F6 day/night cycle).
- **Aurore - Qualite max.command**: ultra shadows and MSAA.
- **Aurore - Vitrine.command**: 17 cinematic shots recorded automatically.

**Ground to orbit with no loading**: cockpit view from the valley up to 60 km altitude, through the cloud layer.

![Continuous climb from an X-wing cockpit: valley, 2 km, 5 km inside the clouds, 10 km, 25 km, 40 km, 60 km, then orbit](artifacts/planet/aurore03-vol.jpg)

**Physical atmosphere and day/night cycle**: noon, golden hour, sunset, dusk, a view from 8 km above the clouds, and the planet seen from orbit.

![Sky and lighting by time of day: valley at noon, golden hour, sunset, dusk, 8 km at sunset and in the afternoon, orbit by day](artifacts/planet/aurore03-ciel-aaa.jpg)

**The showcase**: the Imperial outpost by day, at sunset and at night, a firing turbolaser tower, an AT-AT, the forest, then the planet at the terminator and the valley at night.

![Showcase: Imperial outpost day/sunset/night, turret, AT-AT, forest, skies and orbital views](artifacts/planet/aurore03-vitrine.jpg)

Details, performance and rebuilding: [docs/AURORE-03.md](docs/AURORE-03.md).

## Building and modding the mod

Everything needed to rebuild and modify the planet mod is in git: Lua scripts and tables (`mods/planet/data/tables`), missions, shaders, and the procedural generators in `scripts/`. The ~2.6 GB of models and textures are not in git; they are generated:

```bash
scripts/build_all.sh                 # full rebuild
scripts/build_all.sh --assets-only   # only the git-ignored models/textures
```

It creates `.venv/` from [`requirements.txt`](requirements.txt) (Python 3.10+, numpy, pillow), fetches the FSO 26.2.0 shader sources into `tools/source-26.2.0` when needed, and runs every generator in order. You also need **Fate of the Galaxy 1.1.2** (Knossos.NET) and the **FSO 26.2.0** engine to play. Steps and options: [docs/AURORE-03.md, « Reconstruction »](docs/AURORE-03.md#reconstruction) (in French).

A full rebuild rewrites generated files tracked by git (missions, some tables, shaders): review them with `git diff`. To change a generated mission, edit `scripts/create_planet_mission.py`, not the `.fs2` file.

## Playing on Windows

The mod itself is cross-platform; only the launchers differ. Windows launchers are in [`windows/`](windows/).

1. On the Mac, run `scripts/pack_windows.sh`: it builds `artifacts/SpaceSim-Windows.zip` (about 2.6 GB, the generated planet mod plus the `.bat` launchers).
2. On the Windows PC: install **Knossos.NET** and **Fate of the Galaxy 1.1.2**, then unzip the **FSO 26.2.0** Windows engine (`fs2_open_26_2_0-builds-x64-AVX.zip`, [release page](https://github.com/scp-fs2open/fs2open.github.com/releases/tag/release_26_2_0)) into `engine\` inside the Knossos library.
3. Unzip `SpaceSim-Windows.zip` into the same library and double-click **Aurore - Evasion.bat** (or the coop, cinematic, free-flight launchers).

Step-by-step guide, settings (Vulkan/OpenGL, resolution, shadows) and co-op networking: [windows/LISEZMOI-WINDOWS.txt](windows/LISEZMOI-WINDOWS.txt) (in French). Not yet tested on Windows.

## Terrain 01: ground and continuous climb

A rocky **8 × 8 km** terrain, physical collisions and a Star Destroyer at **6 km altitude**, all in a single mission.

- **Terrain - Vol libre.app** to explore.
- **Terrain - Demonstration.app** for an automatic climb of about 25 seconds, after which you take back control.
- **Terrain - FRED.app** to edit the mission.

At the briefing: **Commit** or **Ctrl + Enter**.

In-game checks passed on the M1 Max. See [the guide and results](docs/TERRAIN-01.md) and [the saved log](artifacts/terrain/validation-m1max.txt). The M1 Mac mini is still to be tested.

## Escorte Aurore: open and play

From this folder in the Finder:

- **SpaceSim FRED.app** opens the mission in QtFRED 26.2.0.
- **Escorte Aurore.app** starts the game on the mission briefing.
- **Ouvrir FRED.command** and **Jouer Escorte Aurore.command** do the same through Terminal.

The launchers set the working directory before starting the engine. Opening the QtFRED application in `tools/FSO-26.2.0` directly can cause the error "cannot be run from a drive root directory".

The Fate of the Galaxy content must stay installed here:

```
~/Library/Application Support/io.github.KnossosNET.Knossos_NET/FreespaceOpen/FotG_R/FotG_R-1.1.2
```

The mission is also symlinked into the game's `data/missions/sp` folder. It appears as **[Rebel] Escorte Aurore** in the mission simulator. The bundled game launcher uses FSO 26.2.0; the 26.0.1 engine already installed in Knossos remains available.

## Scenario

- **Red 1**: your X-wing.
- **Red 2**: your X-wing wingman, tasked with protecting Aurore.
- **Aurore**: a GR-75 transport carrying medical supplies.
- **Alpha 1 and Alpha 2**: two TIEs attacking the transport.

Destroy both TIEs and protect Aurore. Five seconds after they are destroyed, the transport starts its jump to hyperspace. The mission ends automatically six seconds after it leaves. If Aurore is destroyed, the mission fails after seven seconds.

## Editing the mission in FRED

Main file: `missions/_SPT_A99_Aurore.fs2`.

1. Open **SpaceSim FRED.app**.
2. In the **Scene Browser**, select **Aurore**, **Red** or **Alpha**. Expand the squadrons to select individual fighters.
3. Use **Select and Move (M)** to move ships and **Zoom Extents (Shift+Z)** to frame the scene.
4. The **Mission** and **Narrative** menus give access to goals, events, briefings and messages.
5. Run **Tools → Error Checker** after your changes, then save.
6. Launch **Escorte Aurore.app** again to test them.

First exercise: move the TIEs further away, save, and see that the player now has more time to intercept the attack.

## Working files

- `missions/`: editable mission.
- `scripts/install_mission.py`: creates the link into the game installation without overwriting an existing file.
- `scripts/create_mission.py`: initial generator; **do not run it again after editing in FRED**, as it rewrites the mission.
- `scripts/read_lz41.py`: reads compressed assets to inspect examples and specs.
- `scripts/launcher.c`: source of the small macOS launchers.
- `docs/FotG-FRED-reference.txt`: official FotG documentation downloaded for this project.
- `docs/reference/`: reference copies of tables and missions from the local installation.
- `tools/FSO-26.2.0/`: official engine and QtFRED for Apple Silicon Macs.
- `tools/source/`: official 26.0.1 source code, used to check formats and parameters; the engine never needed to be compiled.

## Checks

- Mission opened in QtFRED 26.2.0 with 5 ships and 2 squadrons.
- **Tools → Error Checker: No errors found!**
- Briefing and cockpit loaded in FSO 26.2.0 with the FotG assets.
- Success, failure and balancing still need to be confirmed by a full playthrough.

## Sources

- [Fate of the Galaxy FRED guide](https://docs.google.com/document/d/1HRUfu9wU3tmZcbsOGLo27g_7FQWo7xmVteXNrXKk2Ns/edit)
- [Official engine and QtFRED 26.2.0](https://github.com/scp-fs2open/fs2open.github.com/releases/tag/release_26_2_0)
- [Engine source code](https://github.com/scp-fs2open/fs2open.github.com)

The game's models, textures, sounds and scripts stay in the Knossos installation. This working folder is not a standalone distribution of the game.

---

<a id="francais"></a>

# SpaceSim — prototypes FSO (version française)

[English](#english) · **Français**

## Aurore – Évasion (mission jouable, solo et coop jusqu'à 4 joueurs)

Le cargo rebelle *Aurore* fuit par un canyon sous le feu impérial, monte en orbite, puis doit sauter en hyperespace avant que l'Étoile Noire ne détruise la planète. L'escadron Rouge l'escorte en X-wing.

![Raid complet : canyon au lever du soleil, ascension à travers les nuages, attaque en orbite face au destroyer stellaire, puis saut en hyperespace](artifacts/planet/aurore03-raid-aaa.jpg)

*Le raid d'un bout à l'autre : vol dans le canyon, ascension à travers les nuages, combat en orbite contre le destroyer stellaire, saut en hyperespace.*

| Lanceur | Contenu |
|---|---|
| **Aurore - Evasion.command** | mission jouable (solo), avec briefing et débriefing |
| **Aurore - Evasion coop.command** | menu du jeu : Multijoueur → Héberger → « [Rebel] Aurore - Evasion (coop) » |
| **Aurore - Evasion (cinematique).command** | la cinématique complète |

**En jeu**
- **F10** : vol Arcade (assisté) ou Simulation.
- **Espace** : passer l'intro.
- **Objectifs** : détruire les 10 batteries du canyon (en équipe), protéger l'*Aurore*, puis sauter quand l'ordre est donné.
- **Objectifs secondaires** : la tour de communication (sinon des renforts arrivent) et la navette qui s'enfuit.

**Documentation**
- Plan et état de chaque phase : [docs/PLAN-AURORE-EVASION.md](docs/PLAN-AURORE-EVASION.md).
- Vol de type avion : [docs/VOL-AVION.md](docs/VOL-AVION.md).
- Rendu, performances, armes et crash : [docs/AURORE-03.md](docs/AURORE-03.md).

**Tests automatiques** : `scripts/test_all.sh` (environ 25 min). Il couvre la carte d'altitude, les armes, la cinématique, le crash, le vol, l'IA, la réapparition et la mission complète.


Première mission pour **Fate of the Galaxy 1.1.2**, réalisée avec ses ressources existantes.

## Aurore 03 : planète, atmosphère et nuages « AAA »

Planète de 160 km survolable du sol à l'orbite, sans chargement. Elle a une atmosphère physique avec de vrais couchers de soleil, des nuages volumétriques et un avant-poste impérial avec des tours turbolaser qui tirent, des AT-AT, des forêts et des rochers.

- **Aurore - Vol libre.app** / **Aurore - Sol vers orbite.app** : jeu (F8 trajet auto, F9 vitesse, F7 heure du jour, F6 cycle jour/nuit).
- **Aurore - Qualite max.command** : ombres ultra et MSAA.
- **Aurore - Vitrine.command** : 17 plans cinématiques enregistrés automatiquement.

**Du sol à l'orbite sans chargement** : vue cockpit de la vallée jusqu'à 60 km d'altitude, en traversant la couche nuageuse.

![Montée continue en cockpit X-wing : vallée, 2 km, 5 km dans les nuages, 10 km, 25 km, 40 km, 60 km puis orbite](artifacts/planet/aurore03-vol.jpg)

**Atmosphère physique et cycle jour/nuit** : midi, heure dorée, coucher de soleil, crépuscule, vue à 8 km au-dessus des nuages et planète vue depuis l'orbite.

![Ciel et éclairage selon l'heure : vallée à midi, heure dorée, coucher, crépuscule, 8 km au coucher et l'après-midi, orbite de jour](artifacts/planet/aurore03-ciel-aaa.jpg)

**La vitrine** : l'avant-poste impérial de jour, au coucher et de nuit, une tour turbolaser qui tire, un AT-AT, la forêt, puis la planète au terminateur et la vallée de nuit.

![Vitrine : avant-poste impérial jour/coucher/nuit, tourelle, AT-AT, forêt, ciels et vues orbitales](artifacts/planet/aurore03-vitrine.jpg)

Détails, performances et reconstruction : [docs/AURORE-03.md](docs/AURORE-03.md).

## Construire et modifier le mod

Tout ce qu'il faut pour reconstruire et modifier le mod planète est dans git : scripts Lua et tables (`mods/planet/data/tables`), missions, shaders et générateurs procéduraux dans `scripts/`. Les quelque 2,6 Go de modèles et textures ne sont pas dans git : ils sont générés.

```bash
scripts/build_all.sh                 # reconstruction complète
scripts/build_all.sh --assets-only   # seulement les modèles et textures ignorés par git
```

Le script crée `.venv/` à partir de [`requirements.txt`](requirements.txt) (Python 3.10+, numpy, pillow), récupère si besoin les shaders de FSO 26.2.0 dans `tools/source-26.2.0`, puis lance tous les générateurs dans l'ordre. Pour jouer, il faut aussi **Fate of the Galaxy 1.1.2** (Knossos.NET) et le moteur **FSO 26.2.0**. Étapes et options : [docs/AURORE-03.md, « Reconstruction »](docs/AURORE-03.md#reconstruction).

Une reconstruction complète réécrit des fichiers générés suivis par git (missions, certaines tables, shaders) : les vérifier avec `git diff`. Pour changer une mission générée, modifier `scripts/create_planet_mission.py`, pas le fichier `.fs2`.

## Jouer sous Windows

Le mod est multiplateforme ; seuls les lanceurs changent. Les lanceurs Windows sont dans [`windows/`](windows/).

1. Sur le Mac, lancer `scripts/pack_windows.sh` : il crée `artifacts/SpaceSim-Windows.zip` (environ 2,6 Go : le mod planète généré et les lanceurs `.bat`).
2. Sur le PC Windows : installer **Knossos.NET** et **Fate of the Galaxy 1.1.2**, puis dézipper le moteur **FSO 26.2.0** pour Windows (`fs2_open_26_2_0-builds-x64-AVX.zip`, [page de la version](https://github.com/scp-fs2open/fs2open.github.com/releases/tag/release_26_2_0)) dans `engine\`, dans la bibliothèque Knossos.
3. Dézipper `SpaceSim-Windows.zip` dans cette même bibliothèque et double-cliquer sur **Aurore - Evasion.bat** (ou les lanceurs coop, cinématique, vol libre).

Guide pas à pas, réglages (Vulkan/OpenGL, résolution, ombres) et réseau en coop : [windows/LISEZMOI-WINDOWS.txt](windows/LISEZMOI-WINDOWS.txt). Pas encore testé sous Windows.

## Terrain 01 : sol et montée continue

Le nouveau prototype est prêt : terrain rocheux **8 × 8 km**, collisions physiques et destroyer à **6 km de hauteur**, dans une seule mission.

- **Terrain - Vol libre.app** pour explorer.
- **Terrain - Demonstration.app** pour une montée automatique d’environ 25 secondes, puis reprendre les commandes.
- **Terrain - FRED.app** pour modifier la mission.

Au briefing : **Commit** ou **Ctrl + Entrée**.

Les contrôles en jeu ont réussi sur le M1 Max. Voir [le guide et les résultats](docs/TERRAIN-01.md) et [le journal conservé](artifacts/terrain/validation-m1max.txt). Le Mac mini M1 reste à tester.

## Escorte Aurore : ouvrir et jouer

Depuis ce dossier dans le Finder :

- **SpaceSim FRED.app** ouvre la mission dans QtFRED 26.2.0.
- **Escorte Aurore.app** lance le jeu sur le briefing de la mission.
- Les fichiers **Ouvrir FRED.command** et **Jouer Escorte Aurore.command** font la même chose via Terminal.

Les lanceurs définissent le dossier de travail avant de démarrer le moteur. Ouvrir directement l'application QtFRED située dans `tools/FSO-26.2.0` peut provoquer l'erreur « cannot be run from a drive root directory ».

Le contenu de Fate of the Galaxy doit rester installé ici :

```
~/Library/Application Support/io.github.KnossosNET.Knossos_NET/FreespaceOpen/FotG_R/FotG_R-1.1.2
```

La mission est également reliée par un lien symbolique au dossier `data/missions/sp` du jeu. Elle porte le nom **[Rebel] Escorte Aurore** dans le simulateur de missions. Le lanceur de jeu fourni utilise FSO 26.2.0 ; le moteur 26.0.1 déjà installé dans Knossos reste disponible.

## Scénario

- **Red 1** : votre X-wing.
- **Red 2** : votre ailier en X-wing, chargé de protéger Aurore.
- **Aurore** : un transport GR-75 transportant du matériel médical.
- **Alpha 1 et Alpha 2** : deux TIE qui attaquent le transport.

Détruisez les deux TIE et protégez Aurore. Cinq secondes après leur destruction, le transport engage son départ en hyperespace. La mission se termine automatiquement six secondes après son départ. Si Aurore est détruit, la mission se termine en échec après sept secondes.

## Modifier la mission dans FRED

Fichier principal : `missions/_SPT_A99_Aurore.fs2`.

1. Ouvrir **SpaceSim FRED.app**.
2. Dans **Scene Browser**, sélectionner **Aurore**, **Red** ou **Alpha**. Déplier les escadrons pour sélectionner les chasseurs.
3. Utiliser **Select and Move (M)** pour déplacer les vaisseaux ; **Zoom Extents (Shift+Z)** pour cadrer la scène.
4. Les menus **Mission** et **Narrative** donnent accès aux objectifs, événements, briefings et messages.
5. Utiliser **Tools → Error Checker** après les changements, puis enregistrer.
6. Relancer **Escorte Aurore.app** pour tester les changements.

Premier exercice : déplacer les TIE plus loin, enregistrer et constater que le joueur dispose de plus de temps pour intercepter l'attaque.

## Fichiers de travail

- `missions/` : mission éditable.
- `scripts/install_mission.py` : crée le lien vers l'installation du jeu, sans remplacer un fichier existant.
- `scripts/create_mission.py` : générateur initial ; **ne pas le relancer après une modification dans FRED**, car il réécrit la mission.
- `scripts/read_lz41.py` : lecture des ressources compressées pour consulter les exemples et les caractéristiques.
- `scripts/launcher.c` : source des petits lanceurs macOS.
- `docs/FotG-FRED-reference.txt` : documentation officielle FotG téléchargée pour cette création.
- `docs/reference/` : copies de référence de tables et missions de l'installation locale.
- `tools/FSO-26.2.0/` : moteur et QtFRED officiels pour Mac Apple Silicon.
- `tools/source/` : code source officiel 26.0.1 consulté pour vérifier le format et les paramètres ; aucune compilation du moteur n'a été nécessaire.

## Vérifications

- Mission ouverte dans QtFRED 26.2.0 avec 5 vaisseaux et 2 escadrons.
- **Tools → Error Checker : No errors found!**
- Briefing et cockpit chargés dans FSO 26.2.0 avec les ressources de FotG.
- La réussite, l'échec et l'équilibrage doivent encore être confirmés par un essai complet.

## Sources

- [Guide FRED de Fate of the Galaxy](https://docs.google.com/document/d/1HRUfu9wU3tmZcbsOGLo27g_7FQWo7xmVteXNrXKk2Ns/edit)
- [Moteur et QtFRED officiels 26.2.0](https://github.com/scp-fs2open/fs2open.github.com/releases/tag/release_26_2_0)
- [Code source du moteur](https://github.com/scp-fs2open/fs2open.github.com)

Les modèles, textures, sons et scripts du jeu restent dans l'installation Knossos. Ce dossier de travail ne constitue pas une distribution autonome du jeu.
