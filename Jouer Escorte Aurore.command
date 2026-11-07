#!/bin/zsh
set -e
PROJECT_DIR="${0:A:h}"
GAME_DIR="$HOME/Library/Application Support/io.github.KnossosNET.Knossos_NET/FreespaceOpen/FotG_R/FotG_R-1.1.2"
cd "$GAME_DIR"
exec "$PROJECT_DIR/tools/FSO-26.2.0/fs2_open_26_2_0_arm64.app/Contents/MacOS/fs2_open_26_2_0_arm64" -start_mission _SPT_A99_Aurore -window -res 1440x900 -parse_cmdline_only
