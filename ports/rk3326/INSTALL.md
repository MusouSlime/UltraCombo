# Installing UltraCombo on an RK3326 handheld

Tested on AmberELEC (RG351V / XU Mini M). The port needs **aarch64** and
**glibc 2.34 or newer** — i.e. any recent AmberELEC/EmuELEC build.

## 1. Copy the port to the SD card

Download `UltraCombo.zip` from the release and copy it to the card, then unzip
it into the Ports folder so that you end up with:

```
/roms/ports/UltraCombo.sh
/roms/ports/UltraCombo 2.sh
/roms/ports/port.json
/roms/ports/ultracombo/...
```

(The `/roms/ports` path is what EmulationStation shows as **Ports**; on some
builds it is `/storage/roms/ports`.)

With PortMaster you can also use **Install a Port** and pick the zip.

## 2. Add your game files

Put the ROMs and the hard disk image of MAME's `kinst` and/or `kinst2` sets
into `/roms/ports/ultracombo/run/`. The exact file names are listed in
`run/PUT-GAME-FILES-HERE.txt`; the short version:

- Killer Instinct: `ki-l15d.u98`, `u10-l1` … `u13-l1`, `u33-l1` … `u36-l1`,
  `kinst.chd`
- Killer Instinct 2: `ki2-l14.u98`, `ki2_l1.u10` … `ki2_l1.u13`,
  `ki2_l1.u33` … `ki2_l1.u36`, `kinst2.chd`

Unzip the MAME ROM zips into that folder. The CHD can stay as it is (a folder
`kinst/kinst.chd` inside `run/` works too). No game files are included in the
release.

## 3. Play

Refresh the Ports list in EmulationStation — two new entries appear:

- **UltraCombo** — Killer Instinct (L1.5D; L1.4 selectable in the menu)
- **UltraCombo 2** — Killer Instinct 2

The first launch of each game shows **"PREPARING THE GAME FOR THIS PC"** and
takes a few minutes (it translates the game's code and compiles it with the
bundled Zig into `ultracombo/cache/`). This happens once per game; after that
it starts straight away. If you later change the ROM/CHD, the cache is rebuilt
automatically.

## Controls

| Action | Pad |
|---|---|
| Move | D-pad |
| Quick / Medium / Fierce punch | X / Y / RB |
| Quick / Medium / Fierce kick | A / B / LB |
| Menu (save state, rewind, quit, filters, netplay) | Guide, or Back+Start |

## If something goes wrong

- Nothing happens when you start a game: check `ultracombo/ultracombo-port.log`
  on the card (it is overwritten on every launch).
- "FILES NOT FOUND": the ROMs are not in `run/` or have different names.
- The picture is rotated or cropped: edit `UC_ROTATE` in `UltraCombo.sh`
  (`90` is right for the RG351V/XU Mini M; try `270`).
- Want frame-rate numbers in the log: add `UC_FPSLOG=1` next to the other
  `export` lines in the launcher.

## Uninstall

Delete `UltraCombo.sh`, `UltraCombo 2.sh`, `port.json` and the `ultracombo`
folder from `/roms/ports`.
