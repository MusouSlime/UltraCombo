#!/bin/bash
# PORTMASTER: UltraCombo.zip, UltraCombo.sh
# UltraCombo - Killer Instinct 1 and 2 arcade ports (native, translated code).
#
# Killer Instinct 2. The first entry (UltraCombo.sh) starts Killer Instinct 1.
# The program runs the arcade games' own code, translated to C and compiled into
# cache/rec-<key>.so for this device; the module is prebuilt in this package.
#
# EmulationStation is stopped while the game runs so the program owns DRM master
# (KMS), and it is restarted on exit.

GAME=ki2

XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}

if [ -d "/opt/system/Tools/PortMaster/" ]; then
  controlfolder="/opt/system/Tools/PortMaster"
elif [ -d "/opt/tools/PortMaster/" ]; then
  controlfolder="/opt/tools/PortMaster"
elif [ -d "$XDG_DATA_HOME/PortMaster/" ]; then
  controlfolder="$XDG_DATA_HOME/PortMaster"
elif [ -d "/roms/ports/PortMaster/" ]; then
  controlfolder="/roms/ports/PortMaster"
else
  controlfolder="$(cd "$(dirname "$0")" 2>/dev/null && pwd)/PortMaster"
fi

source "$controlfolder/control.txt"
[ -f "${controlfolder}/mod_${CFW_NAME}.txt" ] && source "${controlfolder}/mod_${CFW_NAME}.txt"
get_controls

GAMEDIR="/$directory/ports/ultracombo"
[ -d "$GAMEDIR" ] || GAMEDIR="$(cd "$(dirname "$0")" && pwd)/ultracombo"
cd "$GAMEDIR" || exit 1

export HOME="${HOME:-/storage}"
export LC_ALL=C
# our bundled SDL2 must win over the system one (2.0.22, too old for this build),
# also when EmulationStation's environment puts other paths in LD_LIBRARY_PATH
export LD_LIBRARY_PATH="$GAMEDIR/lib:${LD_LIBRARY_PATH:-}"
[ -n "${sdl_controllerconfig:-}" ] && export SDL_GAMECONTROLLERCONFIG="$sdl_controllerconfig"
export SDL_VIDEODRIVER="${SDL_VIDEODRIVER:-kmsdrm}"
export SDL_AUDIODRIVER="${SDL_AUDIODRIVER:-alsa}"
export SDL_JOYSTICK_HIDAPI=0
# the panel's native mode is portrait; turn the picture upright
export UC_ROTATE="${UC_ROTATE:-90}"

> "$GAMEDIR/ultracombo-port.log" && exec >> "$GAMEDIR/ultracombo-port.log" 2>&1
echo "=== $(date) start ($GAME) ==="
echo "CFW=${CFW_NAME:-?} display=${DISPLAY:-?}"

ES_MANAGED=0
if pidof emulationstation >/dev/null 2>&1 || [ "$(systemctl is-active emustation 2>/dev/null)" = "activating" ]; then
  echo "stopping EmulationStation for DRM master"
  systemctl stop emustation >/dev/null 2>&1 || true
  ES_MANAGED=1
  for _ in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25; do
    pidof emulationstation >/dev/null 2>&1 || break
    sleep 0.2
  done
  sleep 1
fi

resume_es() {
  if [ "$ES_MANAGED" = 1 ]; then
    systemctl reset-failed emustation >/dev/null 2>&1 || true
    systemctl start emustation >/dev/null 2>&1 || true
  fi
}
trap resume_es EXIT INT TERM

chmod +x "$GAMEDIR/ultracombo" 2>/dev/null
pm_platform_helper "$GAMEDIR/ultracombo" >/dev/null

# EmulationStation's own arguments (-Pports, -p1guid ...) mean nothing to the
# program and would break its restart-the-game path: pass only the game.
"$GAMEDIR/ultracombo" --game "$GAME"
RC=$?
echo "=== exit $RC ==="

resume_es
trap - EXIT INT TERM
pm_finish
exit $RC
