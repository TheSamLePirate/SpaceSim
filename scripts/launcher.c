/* macOS Finder launcher: establish FotG's working directory before starting FSO. */
#include <mach-o/dyld.h>
#include <libgen.h>
#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

int main(void) {
    char executable[PATH_MAX], real_executable[PATH_MAX], project[PATH_MAX];
    uint32_t size = sizeof executable;
    if (_NSGetExecutablePath(executable, &size) != 0 || !realpath(executable, real_executable)) return 1;
    int editor = strstr(real_executable, "SpaceSim FRED.app/") != NULL;
    strlcpy(project, real_executable, sizeof project);
    for (int n = 0; n < 4; ++n) { char *slash = strrchr(project, '/'); if (!slash) return 2; *slash = '\0'; }
    char game[PATH_MAX], binary[PATH_MAX], mission[PATH_MAX];
    const char *home = getenv("HOME");
    if (!home) return 3;
    snprintf(game, sizeof game, "%s/Library/Application Support/io.github.KnossosNET.Knossos_NET/FreespaceOpen/FotG_R/FotG_R-1.1.2", home);
    if (chdir(game) != 0) { perror("Fate of the Galaxy directory"); return 4; }
    if (editor) {
        snprintf(binary, sizeof binary, "%s/tools/FSO-26.2.0/qtfred_26_2_0_arm64.app/Contents/MacOS/qtfred_26_2_0_arm64", project);
        snprintf(mission, sizeof mission, "%s/missions/_SPT_A99_Aurore.fs2", project);
        execl(binary, binary, "-start_mission", mission, "-parse_cmdline_only", (char *)NULL);
    } else {
        snprintf(binary, sizeof binary, "%s/tools/FSO-26.2.0/fs2_open_26_2_0_arm64.app/Contents/MacOS/fs2_open_26_2_0_arm64", project);
        execl(binary, binary, "-start_mission", "_SPT_A99_Aurore", "-window", "-res", "1440x900", "-parse_cmdline_only", (char *)NULL);
    }
    perror("SpaceSim launch");
    return 5;
}
