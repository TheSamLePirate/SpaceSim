/* Double-clickable native launcher; run the mod from its correct library root. */
#include <mach-o/dyld.h>
#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#ifndef PLANET_MODE
#define PLANET_MODE 0
#endif
int main(void) {
 char exe[PATH_MAX],project[PATH_MAX],script[PATH_MAX];uint32_t n=sizeof exe;
 if(_NSGetExecutablePath(exe,&n)||!realpath(exe,project))return 1;
 for(int i=0;i<4;i++){char *p=strrchr(project,'/');if(!p)return 2;*p=0;}
 snprintf(script,sizeof script,"%s/scripts/run_planet.sh",project);
 const char *mode=PLANET_MODE==1||PLANET_MODE==3?"auto":PLANET_MODE==2?"fred":"libre";
 execl("/bin/zsh","zsh",script,mode,PLANET_MODE==3?"ombres":"qualite",(char*)NULL);
 perror("SpaceSim Aurore");return 3;
}
