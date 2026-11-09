# Aurore 03 — rendu planétaire « AAA » dans FSO 26.2

Mod `mods/planet` (lien `SpaceSimPlanet`), moteur FSO 26.2.0 non modifié. Tout le rendu passe par des shaders surchargés dans le mod et des modèles POF générés.

## Contenu

- **Atmosphère physique** (Rayleigh + Mie + ozone, diffusion simple + approximation multiple), évaluée par pixel en espace monde. Elle est **liée à la planète**. On a le même milieu pour le ciel vu du sol, la brume sur le relief (perspective atmosphérique dans le G-buffer différé), la bande d'horizon et le halo vu de l'orbite.
- **Soleil dynamique** : le shader lit la lumière du soleil de la mission. Couchers rouge et orange, heure dorée, crépuscule, nuit. Disque solaire.
- **Nuages volumétriques** (approche Nubis / Horizon Zero Dawn) : volume de bruit Perlin-Worley 128³ précalculé (`scripts/build_cloud_noise.py`), raymarching avec érosion de détail, light-march vers le soleil, diffusion multiple, effet « powder » et ombres des nuages au sol. La couche de nuages est continue du sol à l'orbite.
- **Terrain** : quadtree de 108 tuiles natives à 3 niveaux de détail, avec jupes anti-fissures et collisions BSP. La grille fait 3,3 m au point d'atterrissage, avec du relief de détail jusqu'à environ 10 m. Les matériaux sont procéduraux en espace monde (roche, prairie, forêt, terre, sable, neige selon pente et altitude), avec un relief de détail. L'océan a des vagues, une réflexion de Fresnel du ciel et des reflets du soleil.
- **Sol** : avant-poste impérial (hangars, casernes, bunker, tour de communication, plateformes, réservoirs, murs). Les fenêtres et balises s'éclairent la nuit. La vallée compte 10 tours turbolaser (Defense Satellite#Imp de FotG sur pylônes) qui **tirent**, 3 AT-AT, une navette Lambda, un conteneur BFF-1, des balises, 35 forêts de conifères et 47 champs de rochers.
- **Ombres** portées (cascades FSO) en profil `max`.

## Raid cinématique (`Aurore - Raid.command`)

Plan unique sans coupure, sauf les plans cockpit (coupes franches). Il enchaîne :
- un vol au couchant dans le canyon sous le feu des batteries ;
- la montée à travers les nuages ;
- l'attaque du destroyer ;
- le passage en vitesse lumière vu du cockpit.

Le vaisseau est toujours celui du joueur. La trajectoire est une spline centripète parcourue à vitesse continue (abscisse curviligne). Le saut utilise la vraie séquence du joueur, celle de la touche « subspace », avec les effets FotG.

## Végétation (`scripts/build_planet_vegetation.py`)

Arbres et rochers sont placés là où le shader peint forêt et roche : même volume de bruit, mêmes règles. Ils sont regroupés en secteurs de 1,5 km. FSO limite une mission à 300 modèles, donc chaque secteur forme un seul modèle à sous-objets, avec 4 niveaux de détail (arbres complets, cônes simplifiés, pyramides, vide). Les arbres ont des normales lisses, une occlusion dans les branches, une translucidité à contre-jour et des ombres. Sous la forêt, le sol prend une couleur de litière et une occlusion. Au-delà du dernier niveau de détail, le terrain peint lui-même la canopée.

| Densité | Arbres + rochers | Canyon | Commande |
|---|---|---|---|
| légère | 75 000 + 17 500 | 27 FPS | `--spacing 11 --density 1.0` |
| **par défaut** | **139 000 + 34 000** | **22 FPS** | `--spacing 9 --density 1.3` |
| limite | 264 000 + 70 000 | 14 FPS | `--spacing 7 --density 1.6` |

## Optimisations

Mesures sur le raid, profil `max`. Les chiffres « au départ » ont été pris avant la végétation dense.

| Phase | Au départ | Après optimisation (avec 139 000 arbres) |
|---|---|---|
| Canyon | 16 FPS, 1 % bas 7 | 22 FPS, 1 % bas 13 |
| Montée | 25 FPS, 1 % bas 4 | 53 FPS, 1 % bas 22 |
| Attaque | 50 FPS | 56 FPS, 1 % bas 31 |

- **Saccade chaque seconde** : la télémétrie réécrivait tout le fichier à chaque seconde. Elle est maintenant écrite toutes les 10 s.
- **Rayon d'altitude** : il n'est plus lancé que sur les tuiles situées sous le vaisseau, au lieu des 108.
- **Affichage FPS** : 180 tracés Lua par image coûtaient 35 %. L'affichage est passé à 2 lignes et 30 barres, avec des statistiques calculées deux fois par seconde.
- **Profil `max`** : ombres « high » et anticrénelage SMAA. Le MSAA 4x coûtait 13 ms. Le profil `ultra` garde les ombres « ultra ».
- **Cascades d'ombres** : 120/420/1500/5000 m. Terrain en 144 cellules par tuile (4,6 M de triangles au lieu de 8,1 M) et LOD plus tôt. Les ombres re-rendaient toute la géométrie.
- **Nuages** : la longueur des pas croît avec la distance, l'horizon est plafonné à 38 km et la lumière est échantillonnée en 3 pas au loin. Coût : environ 4 ms au lieu de 13.
- **Entités** : les batteries, AT-AT, navette, conteneur et balises sont retirés au-delà de 9 km et recréés à l'identique en deçà de 7 km. Bâtiments, forêts et rochers passent par un LOD vide au loin.
- **Testé puis écarté** : les « detail boxes » par cellule. La passe d'ombres FSO les ignore et dessine tout le niveau de détail.


## Effets atmosphériques (passe « AAA »)

- **Limbe doux** : l'atmosphère monte à 30 km et une couche stratosphérique ténue (hauteur d'échelle 7 km) prolonge le halo. Le bord vu de l'espace s'estompe au lieu de s'arrêter net. La pénombre du terminateur est plus large.
- **Brume de vallée** : couche de Mie dense près du sol, qui s'allume à contre-jour au coucher.
- **Cirrus** à 9,5 km : voiles en plaques, bruit déformé, éclairés par le soleil rougi (roses au crépuscule). Ils s'effacent quand on les voit par la tranche, ce qui évite un anneau sombre côté nuit.
- **Rayons crépusculaires** : ce sont les light shafts natifs de FSO, activés via `post_processing.tbl` du mod et légèrement réchauffés (`ls-f.sdr`).
- **Tonemapping ACES** (`spacesim-ltp.tbm`, exposition 2,9) : contraste et couleurs plus cinématographiques.
- **Feuillage** : volumes lisses, occlusion dans les branches, translucidité à contre-jour, lumière du ciel diffusée dans le feuillage. Sous la forêt, litière et occlusion au sol. Au-delà du dernier niveau de détail, la canopée est peinte par le terrain.
- **Sécurité** : les valeurs non finies (NaN) sont neutralisées avant l'écriture des pixels, car le bloom de FSO les étalait sur tout le ciel.

Coût mesuré de ces ajouts : négligeable (canyon 23 FPS, montée 53 FPS, attaque 57 FPS avec 139 000 arbres).

## À propos des « freezes » pendant les tests

Les sessions de capture (`capture_planet.sh` et la vitrine) prennent une capture pleine résolution chaque seconde. L'encodage PNG coûte 200 à 250 ms par capture, d'où un gel visible chaque seconde. Ce coût n'existe pas en jeu normal : le seul pic mesuré survient au chargement. Les lanceurs normaux suppriment désormais les fichiers `spacesim-*.flag` laissés par un test interrompu.

## Commandes en vol

| Touche | Effet |
|---|---|
| F8 | trajet automatique sol → orbite / reprendre les commandes |
| F9 | vitesse de croisière 250 / 1500 / 5000 m/s |
| F7 | heure : midi, après-midi, heure dorée, coucher, crépuscule, nuit, aube |
| F6 | cycle jour/nuit continu |

Les FPS s'affichent en haut à droite : moyenne, 1 % bas, pic, et une barre par groupe de 6 images (vert < 17 ms, jaune < 33 ms, rouge au-delà). Pour les masquer, créer `data/spacesim-nofps.flag`.

## Lanceurs

- `Aurore - Vol libre` / `Aurore - Sol vers orbite` : qualité « ultra », sans ombres.
- `Aurore - Qualite max.command` : ombres ultra, MSAA 4x, anisotrope 16x.
- `Aurore - Vitrine.command` : 17 plans automatiques enregistrés dans `artifacts/planet/shots/vitrine/`.

## Performances mesurées (M1 Max, 1440×900)

| Shader | Profil | Sol | Atmosphère | Orbite |
|---|---|---|---|---|
| low | qualité | 26 FPS | 22 | 13 |
| high | qualité | 23 | 17 | 10 |
| ultra | qualité | 20 | 13 | 7 |
| ultra | max (ombres, MSAA, sans l'avant-poste) | 10 | 9 | 5 |
| ultra | max + avant-poste, forêts, rochers | 8 | 8 | 4 |

Changer le niveau du shader : `.venv/bin/python scripts/build_planet_shader.py --quality low|high|ultra`.

La plus grosse dépense vient des nuages volumétriques devant le terrain vu de haut. FSO n'offre ni reprojection temporelle ni rendu à demi-résolution, et chaque pixel les recalcule. Pistes d'optimisation : moins de pas en orbite, LOD de bruit selon la distance, désactivation des nuages devant les objets lointains.

## Reconstruction

Les modèles et textures de `mods/planet/data/models` et `maps` (environ 2,6 Go) ne sont pas dans git : ils sont entièrement procéduraux et se régénèrent avec une seule commande.

```
scripts/build_all.sh                  # tout reconstruire
scripts/build_all.sh --assets-only    # seulement les fichiers ignorés par git (modèles, textures)
scripts/build_all.sh --quality high   # niveau du shader : low | high | ultra (défaut ultra)
scripts/build_all.sh --from tiles     # reprendre à partir d'une étape
```

Le script :
1. crée `.venv/` et installe `requirements.txt` (numpy, pillow ; Python 3.10 ou plus) ;
2. récupère si besoin les shaders officiels de FSO 26.2.0 dans `tools/source-26.2.0` (clone git partiel du tag `release_26_2_0` : seulement `code/def_files/data/effects` et les licences) ;
3. lance les générateurs dans l'ordre des dépendances.

| Étape | Script | Produit |
|---|---|---|
| `planet` | `build_planet.py` | textures des faces `ss_p_*`, ciel, coques d'atmosphère |
| `clouds` | `build_planet_clouds.py` | coques de nuages `ss_c_*` (couche historique) |
| `noise` | `build_cloud_noise.py` | atlas de bruit 3D `ss_air-trans-misc` (nuages, masques forêt/roche) |
| `tiles` | `build_planet_tiles.py --depth 8 --cells 192` | tuiles de terrain et collisions, `artifacts/planet/tiles.json` |
| `heightmap` | `build_planet_heightmap.py` | `spacesim-height.txt` (altitude pour le Lua), lit `tiles.json` |
| `atmosphere` | `build_planet_atmosphere.py` | maillage d'atmosphère unique `ss_atmo_0` |
| `ground` | `build_planet_ground.py` | avant-poste, tours turbolaser, AT-AT, rochers, `ground.json` |
| `vegetation` | `build_planet_vegetation.py --spacing 9 --density 1.3 --boxes` | secteurs de forêt, `vegetation.json` |
| `deathstar` | `build_death_star.py` | Étoile Noire |
| `cine` | `build_cine_assets.py` | noyau, fragments et halos de la destruction de la planète |
| `missions` | `create_planet_mission.py` | toutes les missions de la planète, `spacesim-prp.tbm`, `spacesim-mod.tbm` |
| `shader` | `build_planet_shader.py --quality ultra` | `effects/*.sdr` (atmosphère, nuages, matériaux) |

Les étapes `missions` et `shader` réécrivent des fichiers suivis par git ; les autres réécrivent aussi les `.json` et aperçus de `artifacts/planet`. Après une reconstruction complète, vérifier les changements avec `git diff`. Une modification faite à la main dans une mission générée est perdue à l'étape `missions` : il faut la reporter dans `create_planet_mission.py`.

Vérification : `scripts/capture_planet.sh <dossier> [showcase] [showg]` lance le vol automatique (ou la vitrine), enregistre les captures et la télémétrie, et `scripts/contact_sheet.py` assemble une planche.

## Armes : bug moteur « lasers sans dégâts » (FSO 26.2) et correctif

**Symptôme** : 0 % de dégâts au laser sur toutes les cibles au sol ; les tirs « ne vont pas loin ».

**Cause** (`code/object/collideshipweapon.cpp`, `collide_prop_weapon` → `check_inside_radius_for_big_ships`
→ `prop_weapon_check_collision`) : pour une arme à vitesse constante (`PF_CONST_VEL` : tous les lasers et
turbolasers) qui se trouve dans la sphère d'un prop de plus de 500 m (nos tuiles de terrain), le moteur
prédit l'impact sur toute la durée de vie du tir. Lorsque cet impact est dans le **futur**, il le traite quand
même tout de suite : le tir est détruit dès sa première image, à quelques mètres du canon. Les torpilles
(guidées, donc sans `PF_CONST_VEL`) n'étaient pas touchées.

**Correctif** (`spacesim-planet-sct.lua`) : une fonction d'override `On Weapon Collision` ignore les
impacts sur un prop de plus de 500 m dont le point d'impact est **devant** l'arme. Le moteur revérifie la
paire plus tard et fait exploser le tir quand il atteint vraiment le sol.

**Tirs scriptés** (`spacesim-cine-sct.lua`) :
- `fireLasers` : vrais projectiles KX-9, convergents, tirés par paires depuis les 4 canons d'aile.
- `fireTorpedo` : MG7 guidée (`HomingObject`) visant un point solide de la coque (`solidAim`).
- `fireClearance` : l'attaquant monte jusqu'à ce que sa ligne de tir passe 70 m au-dessus des crêtes, et
  ne tire de torpille que si elle passe à plus de 25 m.
- L'attaquant quitte la formation pour attaquer à environ 800 m.
- Un ailier libre reprend la cible d'un ailier occupé. Les batteries restent toujours au joueur.
- Le cargo devient invulnérable sous 52 % de coque (une salve d'ADM-77 pouvait le tuer en une image).

**Banc de test** : `scripts/cine_test.sh wtest 100 "WTEST RESULT" cinecanyon cinetest`. Le joueur est figé
à 750 m de chaque cible : lasers seuls sur 3 cibles, une torpille seule sur 3 autres.
Résultat attendu : 6/6 DESTROYED.
Test du canyon : `scripts/cine_test.sh canyon 300 "TARGETS|LOST" cinecanyon` → `TARGETS destroyed=23/23`.

## Crash du joueur

- `On Prop Collision` : un chasseur qui touche le terrain à plus de 35 m/s est détruit. On ne laisse pas le
  moteur faire sa réponse de collision, sinon l'épave rebondissait à 337 m/s vers le ciel.
- **En cinématique**, `SPACESIM_PLAYER_CRASH` met en scène le crash, parce que la vue de mort de FSO ignore
  la caméra du script, dérive sous le sol et pointait vers la cible du joueur :
  - le vrai X-wing est masqué et immobilisé ;
  - un clone est détruit à sa place (vraie séquence de mort : boule de feu, débris) ;
  - la caméra reste sur l'épave, 150 m derrière et au-dessus, à un point dégagé du relief ;
  - explosions secondaires pendant 3 s ;
  - après 4 s, `SPACESIM_REAL_DEATH` tue le vrai joueur. FSO déroule alors sa procédure normale : message de
    mort, vue de mort, puis popup Quick Start Mission / Return to Main Menu / Return to Briefing.
  - La vue de mort de FSO est cadrée par deux leviers. Un témoin invisible est crédité du kill, à l'opposé
    du point caméra voulu (le moteur place la caméra à 100 m du côté opposé au tueur). L'épave est orientée
    pour que la dérive de la caméra (2·fvec + 2·rvec + uvec) l'éloigne du sol.
  - Les sous-titres de la cinématique sont coupés après la mort.
- **Hors cinématique** : mort réelle immédiate via `SPACESIM_REAL_DEATH`, avec la même caméra de mort cadrée.
- Test : `STOP_AT=cine_end scripts/cine_test.sh crash 500 "CRASH|DEATHCAM" cinecanyon cinecrash`.
  Le X-wing plonge à T=30 s et la mission s'arrête 20 s après l'impact.

## Phase 2 – performances (07/11, M1 Max, 1440×900, canyon de la cinématique)

| Configuration | FPS canyon | 1 % bas |
|---|---|---|
| OpenGL, ombres niveau 3 (ancien `max`) | 14,3 à 15,3 | 9 à 10 |
| OpenGL, sans ombres | 27,2 | 16 |
| OpenGL, ombres, sans végétation (diagnostic) | 26,2 | 15 |
| OpenGL, ombres, cascades 100/300/1000/3000 m | 14,9 | 9,5 |
| OpenGL, ombres, végétation en cellules à detail boxes | 16,3 | 10,7 |
| **Vulkan, ombres niveau 2 (`qualite`)** | **30,8** | 17,6 |
| **Vulkan, ombres niveau 3 (`max`)** | **26,5 à 30,4** | 14,6 à 15,9 |

Fin de la cinématique sous Vulkan : 81,5 FPS en orbite, 53,5 pendant la destruction (42 sous OpenGL).

**Diagnostic**
- **Les ombres coûtaient 17 ms par image, dont environ 25 ms imputables à la végétation**, dans les 4 cascades d'ombre.
- **Ni la taille des cartes d'ombre ni les distances des cascades ne changent le coût.** C'est la géométrie qui est redessinée 4 fois.
- **Cause sous macOS** : OpenGL 4.1 n'a pas `GL_ARB_shader_viewport_layer_array`. FSO passe alors par un geometry shader pour dupliquer chaque triangle dans les 4 cascades (`shadow_map-v.sdr`, `GEOMETRY_FALLBACK`), ce qui est lent sur les GPU Apple.
- Le moteur Vulkan de FSO 26.2 (MoltenVK fourni avec l'application) écrit la couche directement dans le vertex shader.

**Changements**
- **Profils Vulkan par défaut** (`-vulkan`) :
  - `qualite` : ombres niveau 2 ;
  - `max` : ombres niveau 3, filtrage anisotrope 16x, particules douces ;
  - `ultra` : ombres niveau 4.

  OpenGL reste disponible : `qualite_gl`, `max_gl`, `ombres`, `max_msaa`.
- **Rendu identique, vérifié** sur des plans fixes (forêt de jour, au couchant, sous-bois, vue haute) et sur la destruction de la planète.
- **Végétation générée avec `--boxes`** : arbres complets à moins de 400 m de leur cellule de 750 m, cônes au-delà. FSO 26.2 respecte aussi ces boîtes pendant le calcul des ombres.

**Limites connues sous Vulkan**
- **Décalcomanies d'impact** (traces de tirs sur les coques) : leur pipeline est refusé par MoltenVK (`vertModelMatrix1 missing`). C'est un effet mineur, et les autres effets d'impact restent visibles.
- **Crash intermittent** (une fois) dans `fireball_create`, sur une explosion Lua très lointaine (80 km, rayon de 12 km). Les explosions de la surface pendant le réchauffement de la planète sont donc devenues des particules animées avec la même texture.
- **Le harnais signale désormais les crashs** (processus disparu) avec la pile d'appels du rapport macOS (code de sortie 4).

**Ordre de reconstruction mis à jour** (intégré à `scripts/build_all.sh`, voir [Reconstruction](#reconstruction))
- Végétation : `build_planet_vegetation.py --spacing 9 --density 1.3 --boxes`.
- Nouvelle étape après les tuiles : `build_planet_heightmap.py`.
