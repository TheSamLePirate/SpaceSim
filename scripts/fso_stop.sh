#!/bin/zsh
# Stops every FSO instance and WAITS until none is left (pkill returns before the process is gone).
pkill -f fs2_open_26_2_0_arm64 2>/dev/null
for i in {1..40}; do pgrep -f fs2_open_26_2_0_arm64 >/dev/null || exit 0; sleep 0.25; done
pkill -9 -f fs2_open_26_2_0_arm64 2>/dev/null; sleep 1
pgrep -f fs2_open_26_2_0_arm64 >/dev/null && { echo "fso_stop: une instance refuse de se fermer" >&2; exit 1; }
exit 0
