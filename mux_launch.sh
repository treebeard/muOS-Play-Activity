#!/bin/sh
# HELP: Play Activity
# GRID: Play Activity
# ICON: playactivity

. /opt/muos/script/var/func.sh

if pgrep -f "playbgm.sh" >/dev/null; then
    killall -q "playbgm.sh" "mpg123"
fi

echo app >/tmp/act_go

ROOT="$(GET_VAR device storage/rom/mount)"
APPDIR="$ROOT/MUOS/application/Play Activity/.play-activity"
BINDIR="$APPDIR/bin"
GPTOKEYB="$ROOT/MUOS/emulator/gptokeyb/gptokeyb2"

export SDL_GAMECONTROLLERCONFIG_FILE="/usr/lib/gamecontrollerdb.txt"
export LD_LIBRARY_PATH="$BINDIR/libs.aarch64:$LD_LIBRARY_PATH"

cd "$APPDIR" || exit
SET_VAR "system" "foreground_process" "love"

$GPTOKEYB "love" -c "play-activity.gptk" &
./bin/love .

kill -9 "$(pidof gptokeyb2)"