# RK3326 / AmberELEC port

Everything needed to run UltraCombo on RK3326 handhelds (Anbernic RG351V,
MagicX XU Mini M, ...) with AmberELEC/EmuELEC, and the source changes that
made it work on those devices.

The port itself is a stock UltraCombo build for `aarch64-linux-gnu` plus:

- **picture rotation** for panels whose only DRM mode is portrait
  (`video.c`, `picker.c`, `UC_ROTATE=0|90|180|270`),
- an optional frame-rate log line (`UC_FPSLOG=1`),
- a bundled SDL2 (the system one is usually too old), and
- two PortMaster launchers (one per game) that stop EmulationStation for
  DRM master and restart it on exit.

## Why the source changes

The panels on these handhelds report a single portrait mode (480x640) but are
mounted sideways, so anything drawn normally appears rotated 90 degrees. The
program now composes each frame at its native size, then turns it into the
window (`SDL_RenderCopyExF`). The destination rect must be the *pre-rotation*
size, centred - SDL rotates the destination quad, not just the texture.

`UC_ROTATE` is read once at startup: `90` was right for the RG351V/XU Mini M
class devices; `270` is the other common mounting.

## Building

Needs Zig (any recent version), an aarch64 sysroot with SDL2 2.32 (headers
and a linkable `libSDL2-2.0.so.0`), and the usual nothing-else.

```sh
ZIG=/path/to/zig \
SDL_INC=/path/to/sysroot/usr/include \
SDL_CFG=/path/to/sysroot/usr/include/SDL2 \
SDL_LIB=/path/to/sysroot/usr/lib/aarch64-linux-gnu/libSDL2-2.0.so.0 \
./build-aarch64.sh
```

The script links against glibc 2.31 symbols (`-target aarch64-linux-gnu.2.31`)
so the binary runs on AmberELEC (glibc 2.34) and anything newer.

### SDL2

Do not link the distribution's SDL2. Build 2.32.10 with KMSDRM and ALSA
only (no X11/Wayland/Pulse) and ship it, because the system SDL2 on 2021-era
firmware is 2.0.1x/2.0.22 and lacks symbols this program needs.

One patch is needed on RK3326: the kernel advertises
`DRM_CAP_ASYNC_PAGE_FLIP` but rejects `DRM_MODE_PAGE_FLIP_ASYNC` with
`EINVAL`, which makes SDL do a blocking modeset on every frame and fall
back to audio pacing. See `sdl2-kmsdrm-no-async-flip.patch`.

## The translated game code

The first launch normally compiles the game's translated code on the device.
These handhelds have no compiler, so the port ships the modules prebuilt:

1. run the Windows/Linux x86-64 build once against your own ROMs/CHDs
   (the sources land in `cache/src-<key>/`),
2. cross-compile them with the same flags the program uses
   (`-fPIC -O2 -fvisibility=hidden -fno-stack-protector -fno-strict-aliasing
   -DREC_MODULE -I<src>`), link `-shared -nostdlib` into
   `cache/rec-<key>.so`,
3. ship `cache/rec-<key>.so` next to the program.

`-O2` (rather than the `-O1` the on-device build uses) is worth ~10-20 % on
the Cortex-A35.

## Runtime layout

```
UltraCombo.sh, UltraCombo 2.sh   PortMaster launchers
port.json
ultracombo/
  ultracombo                     the aarch64 binary
  lib/libSDL2-2.0.so.0           bundled SDL2
  run/                           ROMs + kinst.chd / kinst2.chd
  cache/rec-<key>.so             prebuilt translated modules
```

The launchers export `LD_LIBRARY_PATH="$GAMEDIR/lib:..."` (the system SDL2
must not win), `SDL_VIDEODRIVER=kmsdrm`, `SDL_AUDIODRIVER=alsa` and
`UC_ROTATE=90`.

## Measured

Anbernic RG351V (RK3326, 4x A35, CPU governor `performance`), 480x640 panel:

| Game | FPS | Emulated frame | Speed |
|---|---|---|---|
| KI1 | 59.6 | 11.4 ms | ~150 % |
| KI2 | 54 | 14-24 ms | 70-120 % (scene dependent) |

KI2 is the heavier one; its frame time varies a lot with the attract-mode
scene. Raising the SoC's first thermal trip from 70 C to 74 C gave ~+12 %
in sustained play (the A35 is clocked at 2 GHz only while it stays cool).
