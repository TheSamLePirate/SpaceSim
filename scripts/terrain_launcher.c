/* Finder launcher for the terrain proof; no Terminal window is required. */
#include <mach-o/dyld.h>
#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/stat.h>
#ifndef TERRAIN_MODE
#define TERRAIN_MODE 0
#endif
int main(void) {
    char executable[PATH_MAX],resolved[PATH_MAX],project[PATH_MAX];
    uint32_t size=sizeof executable;
    if (_NSGetExecutablePath(executable,&size)!=0 || !realpath(executable,resolved)) return 1;
    strlcpy(project,resolved,sizeof project);
    for(int i=0;i<4;i++){char *end=strrchr(project,'/');if(!end)return 2;*end=0;}
    const char *home=getenv("HOME"); if(!home)return 3;
    char library[PATH_MAX],link[PATH_MAX],source[PATH_MAX],binary[PATH_MAX],mission[PATH_MAX];
    snprintf(library,sizeof library,"%s/Library/Application Support/io.github.KnossosNET.Knossos_NET/FreespaceOpen",home);
    snprintf(link,sizeof link,"%s/SpaceSimTerrain",library);
    snprintf(source,sizeof source,"%s/mods/terrain",project);
    struct stat info;
    if(lstat(link,&info)!=0 && symlink(source,link)!=0){perror("SpaceSimTerrain link");return 4;}
    if(chdir(library)!=0){perror("Knossos library");return 5;}
    const char *mods="SpaceSimTerrain,FotG_R/FotG_R-1.1.2";
    if(TERRAIN_MODE==2){
        snprintf(binary,sizeof binary,"%s/tools/FSO-26.2.0/qtfred_26_2_0_arm64.app/Contents/MacOS/qtfred_26_2_0_arm64",project);
        snprintf(mission,sizeof mission,"%s/mods/terrain/data/missions/_SPT_Terrain_Libre.fs2",project);
        execl(binary,binary,"-mod",mods,"-start_mission",mission,"-parse_cmdline_only",(char*)NULL);
    } else {
        snprintf(binary,sizeof binary,"%s/tools/FSO-26.2.0/fs2_open_26_2_0_arm64.app/Contents/MacOS/fs2_open_26_2_0_arm64",project);
        const char *name=TERRAIN_MODE==1?"_SPT_Terrain_Auto":"_SPT_Terrain_Libre";
        execl(binary,binary,"-mod",mods,"-start_mission",name,"-window","-res","1440x900","-parse_cmdline_only",(char*)NULL);
    }
    perror("SpaceSim terrain");return 6;
}
