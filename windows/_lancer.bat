@echo off
rem Lanceur commun SpaceSim pour Windows. Ne pas l'ouvrir directement : utiliser les autres .bat.
rem Usage : _lancer.bat <mission ou "menu">
setlocal

rem ---- Reglages a adapter -------------------------------------------------
rem Rendu : laisser -vulkan, ou mettre RENDU= (vide) pour OpenGL si ecran noir / crash au demarrage.
set "RENDU=-vulkan"
rem Resolution de la fenetre.
set "RES=1920x1080"
rem Qualite des ombres : 0 (aucune) a 4 (ultra). 2 si le jeu rame.
set "OMBRES=3"
rem -------------------------------------------------------------------------

cd /d "%~dp0"

if not exist "SpaceSimPlanet\data\missions" (
  echo [Erreur] Dossier SpaceSimPlanet introuvable a cote de ce fichier.
  echo Ces .bat doivent etre dans la bibliotheque Knossos, a cote de FotG_R et SpaceSimPlanet.
  pause & exit /b 1
)
if not exist "FotG_R\FotG_R-1.1.2" (
  echo [Erreur] Fate of the Galaxy 1.1.2 introuvable : FotG_R\FotG_R-1.1.2
  echo Installez-le avec Knossos.NET dans cette meme bibliotheque.
  pause & exit /b 1
)

rem Moteur FSO 26.2.0 : premier fs2_open_*.exe (hors versions de debogage) dans engine\
set "FSO="
for %%F in ("engine\fs2_open_*.exe") do (
  echo %%~nF | findstr /i "FASTDBG DEBUG" >nul || if not defined FSO set "FSO=%%~fF"
)
if not defined FSO (
  echo [Erreur] Moteur introuvable : engine\fs2_open_*.exe
  echo Telechargez fs2_open_26_2_0-builds-x64-AVX.zip sur
  echo https://github.com/scp-fs2open/fs2open.github.com/releases/tag/release_26_2_0
  echo et dezippez-le dans le dossier engine\ a cote de ce fichier.
  pause & exit /b 1
)

set "MISSION="
if /i not "%~1"=="menu" set "MISSION=-start_mission %~1"

set "QUALITE=-enable_shadows -shadow_quality %OMBRES% -anisotropic_filter 16 -soft_particles"
if "%OMBRES%"=="0" set "QUALITE=-shadow_quality 0 -anisotropic_filter 16"

echo Lancement : %FSO%
start "" "%FSO%" -mod "SpaceSimPlanet,FotG_R/FotG_R-1.1.2" %MISSION% -window -res %RES% -aa -aa_preset 6 %RENDU% %QUALITE% -parse_cmdline_only
endlocal
