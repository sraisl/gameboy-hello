# Game Boy "Hello World" (RGBDS Assembly)

Ein minimales Nintendo Game Boy (DMG) Projekt in RGBDS-Assembly, das
**"HELLO WORLD!"** auf dem Bildschirm rendert. Gebaut mit dem
[gameboy-programmer](https://github.com/sraisl/skills/tree/main/gameboy-programmer)
Skill-Workflow.

## Struktur

```
gameboy-hello/
├── main.rgbasm        ; Entry point, VRAM-Setup, Tilemap-Schreiben, LCD-Enable
├── font.rgbasm        ; 8x8 Pixel-Font (2bpp) für "HELLO WORLD!"
├── hardware.rgbinc    ; Game Boy Hardware-Register Definitionen
├── Makefile           ; RGBDS Build-Pipeline
└── game.gb            ; Kompilierte ROM (nach `make`)
```

## Voraussetzungen

- **RGBDS** (rgbasm, rgblink, rgbfix) — Assembly-Toolchain
- **SameBoy** (oder jeder andere Game Boy Emulator) — zum Testen

### Installation (Ubuntu/Debian)

```bash
# Build-Deps
sudo apt-get update
sudo apt-get install -y build-essential git bison flex \
    pkg-config libpng-dev zlib1g-dev libsdl2-dev libepoxy-dev \
    xvfb xauth

# RGBDS aus Quellen bauen
git clone https://github.com/gbdev/rgbds.git
cd rgbds && make -j$(nproc) && sudo make install && cd ..

# SameBoy (Emulator) bauen
git clone https://github.com/LIJI32/SameBoy.git
cd SameBoy && make CONF=release && sudo cp build/bin/SDL/sameboy /usr/local/bin/
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

## Testen mit SameBoy

SameBoy ist eine SDL-GUI-Anwendung. Auf einem Desktop einfach:

```bash
sameboy game.gb
```

Auf einem **Headless-Server** (ohne Display) nutzt man `xvfb`, um einen
virtuellen Framebuffer bereitzustellen:

```bash
xvfb-run -a sameboy game.gb
```

Das startet den Emulator; du solltest "HELLO WORLD!" auf schwarzem
Hintergrund (hellgraue Schrift) sehen.

### Screenshot erstellen (Headless)

SameBoy speichert einen Screenshot, wenn man im Emulator-Fenster
**F9** drückt (PNG in das aktuelle Verzeichnis). Headless geht das via
xvfb + `xdotool`:

```bash
xvfb-run -a bash -c '
  sameboy game.gb &
  SB=$!
  sleep 3
  xdotool key F9        # Screenshot auslösen
  sleep 1
  kill -TERM $SB
  wait $SB
'
ls -la *.png            # sameboy_*.png
```

> Hinweis: Audio-Warnungen (`ALSA lib ... cannot find card`) unter headless
> sind harmlos — der Emulator läuft trotzdem.

## Wie es funktioniert

1. **Entry point** (`$0100`): `jp Start`, danach Nintendo-Logo-Padding.
2. **Start**: Interrupts aus, Stack-Pointer setzen, auf VBlank warten
   (VRAM sicher beschreibbar).
3. **Font kopieren**: Die 9 Glyphen (8x8, 2bpp) aus ROM → VRAM `$8000`.
4. **Tilemap schreiben**: Die Tile-Indizes von `"HELLO WORLD!"` werden ab
   `$9800 + 3*32 + 6` (Zeile 3, Spalte 6) in die Hintergrund-Tilemap
   geschrieben.
5. **LCD an**: `LCDC` mit BG-on, Tilemap/Tiles-Adressen, Palette
   `%11100100` (dunkel auf hell).
6. **Main loop**: `halt` (Stromsparen), wartet auf NMI/Interrupt.

## Anpassen

- **Text ändern**: In `main.rgbasm` den `Message:`-Block anpassen.
  Tile-Indizes: `0=space 1=H 2=E 3=L 4=O 5=W 6=R 7=D 8=!`.
  Neue Buchstaben in `font.rgbasm` ergänzen (16 Bytes pro Glyph,
  2bpp: Bit 1 = dunkler Pixel).
- **Position**: Start-Adresse `$9800 + row*32 + col` im `.writeMsg`-Block.
- **Farbe**: `rBGP` Wert ändern (`%11100100` = dunkel auf hell,
  `%00011001` = hell auf dunkel).

## Verifikation

- [x] `make` läuft fehlerfrei durch (rgbasm -Weverything -Werror)
- [x] `rgbfix --validate` meldet "ROM VALID"
- [x] ROM lädt in SameBoy ohne "invalid ROM"-Fehler
- [x] Tilemap enthält korrekt decodiert "HELLO WORLD!"

## Lizenz

MIT — mach was du willst.
