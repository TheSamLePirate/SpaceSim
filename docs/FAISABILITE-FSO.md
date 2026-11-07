# SpaceSim — faisabilité avec FreeSpace Open uniquement

Recherche du 7 novembre 2026, fondée sur FSO 26.2.0, son code source officiel et le guide de création de Fate of the Galaxy présent dans ce projet.

## Contraintes retenues

- FSO uniquement ; aucun changement vers Unreal ou un autre moteur.
- Quatre joueurs : Sam, Barth, Luigi et Trini.
- Deux machines Windows, deux Mac ; M1 Max indiqué pour le matériel Mac, RAM et modèle de l'autre Mac non précisés.
- Univers Star Wars et ressources FotG pour commencer.
- Priorité : liberté de vol, y compris surface, atmosphère et espace sans coupure.
- Cette étape est une analyse. La mission Escorte Aurore n'est pas encore transformée en mission réseau.

## Conclusion

FSO peut servir de base à un véritable jeu coopératif personnalisé : histoire, missions, quatre appareils différents, peinture, armement, menus, son, progression et batailles contre un vaisseau amiral. La qualité finale dépendra surtout du contenu, du travail artistique et des tests réseau.

Le moteur ne fournit pas une planète explorable complète avec terrain détaillé chargé progressivement. Cela ne rend pas tout vol continu impossible : un relief et une zone de combat en altitude peuvent coexister dans une seule mission, donc être parcourus sans changement de scène. Une petite lune sphérique préchargée constitue également une hypothèse de prototype crédible. Ces solutions demandent de créer la géométrie et de tester les collisions, la lisibilité, l'IA et les performances. Elles ne sont pas une fonctionnalité déjà validée dans SpaceSim.

## Planètes et relief : trois cas différents

1. **Planète de fond** : image/skybox. Les montagnes éventuellement visibles sont peintes. Pas de terrain géométrique survolable ou de collision avec ces détails. Le guide FotG documente `skybox_planet.pof` pour les combats proches des planètes. Les missions fournies « Space: Hoth » et « Space: Yavin » consultées utilisent ce type de mise en scène spatiale ; leur nom ne démontre pas un terrain planétaire.
2. **Terrain local en 3D** : montagne, canyon, base ou tranchée modélisés en POF, utilisés comme géométrie de décor avec collisions. FSO 26.2 possède un système de props, des niveaux de détail, un contrôle des collisions et une API Lua `mn.createProp`. Une carte peut être entièrement préchargée ; le joueur peut alors passer du sol à une zone élevée sans chargement. Étendue, densité et hauteurs restent à mesurer.
3. **Petite lune sphérique** : surface courbe construite en 3D, relief inclus, éventuellement découpée en morceaux. Si tous les éléments tiennent en mémoire et dans une scène de taille raisonnable, il est plausible de voler tout autour puis de rejoindre un vaisseau placé en hauteur. Il faut le démontrer dans un prototype, d'abord sans atmosphère ni simulation orbitale. Une mini-lune est une proposition de design, pas une capacité native de génération planétaire.

Pour une planète de taille réelle, il faudrait résoudre au minimum la précision des coordonnées, les niveaux de détail entre orbite et sol, le chargement et déchargement des terrains/collisions, la gravité radiale et les joueurs dispersés. Les positions centrales du moteur utilisent des vecteurs `float` 32 bits ; ce constat invite à limiter l'échelle, sans constituer à lui seul une limite de distance universelle. FSO n'apporte pas de pipeline complet pour ce problème. Un développement C++ serait à envisager pour une architecture de très grands mondes fiable.

## Gravité et atmosphère

Le moteur possède bien de la gravité : accélération au niveau de la mission et coefficient par objet, accessibles dans le code et l'API. La gravité de base est un vecteur partagé par la mission, pas une attraction radiale autonome autour de plusieurs planètes. Pour une lune complète, la gravité radiale et ses conséquences réseau constituent un développement particulier.

Un jeu de chasseurs Star Wars peut commencer avec un vol arcade et une sustentation implicite : une simulation orbitale réaliste n'est pas nécessaire pour permettre le trajet sol-espace.

Ciel, brouillard, particules, modèles transparents et effets visuels peuvent suggérer une atmosphère. Obtenir une transition convaincante, dépendant de l'altitude de chaque joueur, reste un travail de rendu et de scripts ; aucune promesse de rendu atmosphérique physiquement réaliste n'est faite. Un effet local au cockpit doit dépendre de la caméra de chaque client, et ne pas modifier un état global commun aux quatre joueurs.

## Ce que l'on peut programmer

### FRED et données

- Quatre emplacements joueurs, appareils distincts et choix d'équipement.
- Missions à étapes, objectifs, renforts, dialogues, briefings et débriefings.
- Ordres IA, attaques de sous-systèmes, temporisations et embranchements.
- Classes de vaisseaux, armes, accélération, boucliers, coque, textures et sons.
- Décors, éclairage, effets, placement des objets et scènes dirigées.

### Lua

- Capacités propres à un appareil : réparation, brouillage ou surpuissance avec recharge, sous réserve de validation réseau.
- HUD et interfaces personnalisés, notifications et retours visuels.
- Création de vaisseaux/props, logique de rencontre, comportements particuliers.
- Progression et état de campagne personnalisés ; définir où l'état est enregistré et qui en est l'autorité.
- Synchronisation des nouveaux états par variables réseau et RPC. `multi.addRPC` et `multi.isServer` existent dans FSO 26.2.

Attention : il est inexact de conclure que tout code Lua s'exécute uniquement sur le serveur. L'API actuelle prévoit des scripts côté serveur et côté clients. Les décisions de gameplay doivent avoir une autorité unique, et les effets locaux rester locaux. Le guide FotG avertit aussi que certains SEXPs de missions solo ne conviennent pas au multijoueur.

### C++ et shaders

Il est possible de modifier le moteur, son rendu, sa physique et ses protocoles. Une fonctionnalité absente de Lua peut être exposée par une modification C++. Cela impose de maintenir et distribuer des builds Windows et macOS cohérents et de tester leur compatibilité réseau. Accéder aux sources ne transforme pas une fonction lourde en petite modification.

Un FPS complet à pied, un équipage de quatre humains dans un même vaisseau ou une simulation de planètes entières ne sont pas des fonctions de jeu fournies clés en main.

## Multijoueur à quatre

FSO possède les bases de la coopération et FotG fournit un modèle de mission multijoueur. Le code 26.2 définit un maximum de 12 joueurs ; quatre joueurs sont donc dans l'enveloppe prévue. Cela ne garantit pas les performances d'une scène remplie de tourelles, projectiles et modèles détaillés.

Un joueur peut héberger ; un serveur séparé est également possible. Windows et macOS sont des plateformes du moteur, mais il faut valider ensemble vos quatre installations avec le même contenu, une version de moteur compatible et les mêmes scripts. Une rencontre à distance suppose aussi de configurer la connectivité : découverte PXO ou connexion directe, et accessibilité de l'hôte selon les réseaux.

Le point technique le plus important est la synchronisation des fonctions ajoutées. Le test décisif fera regarder une même destruction de sous-système, un même déclenchement d'objectif et un même respawn sur les quatre machines. Les placements/couleurs personnels et l'attribution des rôles doivent aussi être contrôlés après réapparition.

## À quel point cela peut ressembler à un jeu AAA ?

On peut viser une aventure indépendante très soignée : identité visuelle propre, cohérence des menus, cockpits, voix, musique, bruitages, mise en scène et bataille lisible. FSO comprend notamment PBR et éclairage/ombres modernes ; la qualité ne dépend pas seulement de l'âge initial du moteur.

La production d'assets originaux de qualité est un poste majeur : modèle, textures, cockpit, animations, points de tir, collisions, niveaux de détail et son. Une nouvelle peinture coûte beaucoup moins de travail qu'un nouveau vaisseau complet. Éviter de chiffrer un résultat en « pourcentage de AAA » : il n'existe pas de mesure commune de ce type.

Le M1 Max fait déjà fonctionner notre première mission ; aucune performance cible pour un niveau planétaire ou quatre clients n'a encore été mesurée. Le terrain et la bataille devront être testés sur les machines réelles.

## Proposition pour Sam, Barth, Luigi et Trini

Titre de travail : **Les Quatre d'Aurore**. Le transport Aurore ravitaille une cellule rebelle poursuivie par le destroyer impérial **Vigilance**. Les quatre amis sont un petit escadron indépendant.

Répartition possible, à changer selon leurs préférences :

- Sam : X-wing polyvalent.
- Barth : Y-wing, torpilles et attaques de sous-systèmes.
- Luigi : A-wing, interception et protection des bombardiers.
- Trini : B-wing, assaut lourd.

Chaque appareil peut recevoir son nom, une livrée, un indicatif et une capacité. Les premiers essais peuvent utiliser les appareils existants, puis ajouter les variations personnelles.

Premier épisode réalisable avec la base de jeu existante : protéger Aurore, intercepter les TIE, neutraliser certaines tourelles du Vigilance, exposer puis frapper une cible critique et couvrir le départ du transport. Les étapes servent la coopération ; on ne suppose pas que quatre chasseurs détruiront rapidement un destroyer avec ses valeurs par défaut.

Version planétaire envisagée : même aventure autour d'une petite lune ; base dans un canyon, montée vers le Vigilance, assaut et retour au terrain dans la même mission. Cette version dépend du résultat du prototype de terrain, et n'est pas annoncée comme déjà fonctionnelle.

## Ordre de validation recommandé

1. Démontrer une mission coopérative simple sur deux Windows et deux Mac.
2. Démontrer séparément un terrain à relief avec collisions, vol au ras du sol et montée continue vers un appareil en altitude.
3. Essayer une petite lune sphérique et l'effet atmosphérique seulement si le terrain local est satisfaisant.
4. Tester un joueur au sol pendant qu'un autre combat en hauteur, puis répartir les quatre autour de la lune.
5. Réunir les systèmes validés et produire histoire, livrées, voix et mise en scène.

Cette progression garde FSO comme moteur tout en vérifiant tôt la liberté de déplacement demandée.

## Sources primaires consultées

- [Site FotG : plateformes, contenu, multijoueur et FRED](https://www.fateofthegalaxy.net/)
- [Guide FRED officiel de FotG](https://docs.google.com/document/d/1HRUfu9wU3tmZcbsOGLo27g_7FQWo7xmVteXNrXKk2Ns/edit) ; copie locale `FotG-FRED-reference.txt`, sections Multiplayer Missions et Skyboxes for Closeup Planets.
- [FSO 26.2 : types, coordonnées et nombre de joueurs](https://github.com/scp-fs2open/fs2open.github.com/blob/release_26_2_0/code/globalincs/pstypes.h)
- [Props, modèles et collisions](https://github.com/scp-fs2open/fs2open.github.com/blob/release_26_2_0/code/prop/prop.cpp)
- [API Lua mission : props et gravité](https://github.com/scp-fs2open/fs2open.github.com/blob/release_26_2_0/code/scripting/api/libs/mission.cpp)
- [API Lua physique](https://github.com/scp-fs2open/fs2open.github.com/blob/release_26_2_0/code/scripting/api/objs/physics_info.cpp)
- [API Lua réseau : serveur et RPC](https://github.com/scp-fs2open/fs2open.github.com/blob/release_26_2_0/code/scripting/api/libs/multi.cpp)
- [Paramètres des vaisseaux et cockpits](https://wiki.hard-light.net/index.php/Ships.tbl)
- [SCPUI : personnalisation des interfaces](https://wiki.hard-light.net/index.php/Scpui)
- [Guide de développement multijoueur](https://wiki.hard-light.net/index.php/Multiplayer_developer_guide)

La documentation wiki étant partiellement inaccessible au navigateur, les points structurants ont été recoupés avec les sources officielles 26.2.0 téléchargées dans `tools/source-26.2.0/` et les fichiers de FotG installés localement. La proposition de mini-lune est une déduction technique à prototyper, pas un résultat mesuré.
