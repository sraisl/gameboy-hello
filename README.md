# Game Boy "Hello World" (RGBDS Assembly)

Ein minimales Nintendo Game Boy (DMG) Projekt in RGBDS-Assembly, das
**"HELLO WORLD!"** auf dem Bildschirm rendert. Gebaut mit dem
[gameboy-programmer](https://github.com/sraisl/skills/tree/main/gameboy-programmer)
Skill-Workflow.

## Struktur

```
gameboy-hello/
├── main.rgbasm        ; Entry point, VRAM-Setup, Tilemap-Aufbau, LCD-Enable
├── font.rgbasm        ; 8x8 Pixel-Font (2bpp) für "HELLO WORLD!"
├── hardware.rgbinc    ; Game Boy Hardware-Register Definitionen
├── Makefile           ; RGBDS Build-Pipeline
└── game.gb            ; Kompilierte ROM (nach `make`)
```

## Voraussetzungen

- **RGBDS** (rgbasm, rgblink, rgbfix) — Assembly-Toolchain
- **mGBA** (oder ein anderer Game-Boy-Emulator) — zum Testen

### Installation (Ubuntu/Debian)

```bash
# Build-Deps
sudo apt-get update
sudo apt-get install -y build-essential git bison flex \
    pkg-config libpng-dev zlib1g-dev

# RGBDS aus Quellen bauen
git clone https://github.com/gbdev/rgbds.git
cd rgbds && make -j$(nproc) && sudo make install && cd ..

```

## Bauen

```bash
make            # erzeugt game.gb
make clean      # räumt auf
```

Die Pipeline (aus dem gameboy-programmer Skill):

```bash
rgbasm -Weverything -Werror -o main.o main.rgbasm
rgblink --dmg --tiny -m game.map -n game.sym -o game.gb main.o
rgbfix --title HELLO --pad-value 0 --validate game.gb
```

`rgbfix --validate` prüft die ROM-Struktur (Header, Padding). Bei Erfolg:
`game.gb: Game Boy ROM image: "HELLO" (Rev.00) [ROM ONLY]`.

## Testen mit mGBA

Unter macOS mit installierter mGBA-App:

```bash
open -a mGBA game.gb
```

Wenn das `mgba`-Programm im `PATH` liegt:

```bash
mgba game.gb
```

Du solltest dunkle Schrift auf einem hellen Hintergrund sehen.

## Wie es funktioniert

1. **Entry point** (`$0100`): `jp Start`, danach Nintendo-Logo-Padding.
2. **Start**: Interrupts aus, Stack-Pointer setzen, auf VBlank warten
   (VRAM sicher beschreibbar).
3. **Font kopieren**: Die 9 Glyphen (8x8, 2bpp) aus ROM → VRAM `$8000`.
4. **Tilemap aufbauen**: Die Tilemap bei `$9800` wird gelöscht; danach werden
   die Tile-Indizes von `"HELLO WORLD!"` ab `$9800 + 3*32 + 6`
   (Zeile 3, Spalte 6) geschrieben.
5. **LCD an**: `LCDC` mit BG-on, Tilemap/Tiles-Adressen, Palette
   `%11100100` (dunkel auf hell).
6. **Main loop**: Eine Endlosschleife hält das statische Bild aktiv.

## Anpassen

- **Text ändern**: In `main.rgbasm` den `Message:`-Block anpassen.
  Tile-Indizes: `0=space 1=H 2=E 3=L 4=O 5=W 6=R 7=D 8=!`.
  `$FF` beendet die Nachricht.
  Neue Buchstaben in `font.rgbasm` ergänzen (16 Bytes pro Glyph,
  zwei aufeinanderfolgende Bitplane-Bytes pro Pixelzeile).
- **Position**: Start-Adresse `$9800 + row*32 + col` im `.writeMsg`-Block.
- **Farbe**: `rBGP` Wert ändern (`%11100100` = dunkel auf hell,
  `%00011001` = hell auf dunkel).

## Verifikation

- [x] `make` läuft fehlerfrei durch (rgbasm -Weverything -Werror)
- [x] `rgbfix --validate` meldet "ROM VALID"
- [x] ROM lädt in mGBA 0.10.5 ohne ROM- oder Headerfehler
- [x] Tilemap enthält korrekt decodiert "HELLO WORLD!"

## Lizenz

MIT — mach was du willst.
