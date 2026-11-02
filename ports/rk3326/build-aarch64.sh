#!/bin/sh
# Build UltraCombo for aarch64 Linux (RK3326 handhelds, glibc 2.31+).
#
# Environment:
#   ZIG       zig executable (default: zig from PATH)
#   SDL_INC   directory containing SDL.h (e.g. .../usr/include)
#   SDL_CFG   directory containing SDL2/SDL.h and SDL_config.h
#   SDL_LIB   path to the aarch64 libSDL2-2.0.so.0 to link against
#   OUT       output binary (default: build-a64/ultracombo)
#
# The binary gets RUNPATH $ORIGIN/lib, so ship libSDL2-2.0.so.0 in lib/
# next to it (or adjust with patchelf).
set -e

ZIG=${ZIG:-zig}
SDL_INC=${SDL_INC:?set SDL_INC to the SDL2 include directory}
SDL_CFG=${SDL_CFG:-$SDL_INC/SDL2}
SDL_LIB=${SDL_LIB:?set SDL_LIB to an aarch64 libSDL2-2.0.so.0}
OUT=${OUT:-build-a64/ultracombo}
TARGET=aarch64-linux-gnu.2.31

ROOT=$(cd "$(dirname "$0")/../.." && pwd)
cd "$ROOT"

CC="$ZIG cc -target $TARGET -O2 -w -I$SDL_INC -I$SDL_CFG"
CHDR=src/third_party/libchdr
CHDR_INC="-I$CHDR/include -I$CHDR/deps/lzma-26.02/include -I$CHDR/deps/miniz-3.1.2 -I$CHDR/deps/zstd-1.5.7"

mkdir -p build-a64/obj dist

# the embedded headers the on-device builder needs (python3)
[ -f build-a64/rec_headers.c ] || python3 tools/embed.py build-a64/rec_headers.c \
    rec_abi_h=src/rec_abi.h rec_gen_h=src/rec_gen.h adsp_core_h=src/adsp_core.h

SRC="main cpu disasm mem ide dcs adsp adsprec rec frontend config osd png state video
     shaders icon adjust recomp rec_build training net netplay game game_ki1 game_ki2
     picker controller_labels launch"

for f in $SRC; do
    $CC -c -o "build-a64/obj/$f.o" "src/$f.c"
done
$CC -c -o build-a64/obj/rec_none.o src/rec_none.c
$CC -c -o build-a64/obj/rec_headers.o build-a64/rec_headers.c
$ZIG cc -target $TARGET -O2 -w $CHDR_INC -c -o build-a64/obj/libchdr.o src/third_party/libchdr_all.c

$ZIG cc -target $TARGET -o "$OUT" build-a64/obj/*.o "$SDL_LIB" \
    -Wl,-rpath,'$ORIGIN/lib' -lm -ldl

echo "built $OUT"
