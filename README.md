# Air Strike 2077

A vertical arcade plane shooter for **Godot 4.7**, in the style of the classic
mobile shmups: your fighter holds the bottom of the screen over a
scrolling ocean while formations of enemy planes, helicopters, bombers and
rockets pour down, punctuated by a giant four-engine boss bomber.

Everything is generated in code — **the project contains no image or audio
files**. Sprites are built from ASCII pixel-art tables (`scripts/Art.gd`), the
boss and the sea are drawn procedurally, explosions are rendered frame by frame,
and every sound effect is a synthesised 16-bit WAV (`scripts/Sfx.gd`).

## Running it

```bash
godot --path .
```

Or open the folder in the Godot editor and press F5.

## Controls

| Action | Input |
| --- | --- |
| Move | Mouse drag / touch, or WASD / arrow keys |
| Fire | Automatic |
| Bomb (clears bullets, damages everything) | `Space`, or the on-screen button (bottom left) |
| Start / retry | `Enter` or click / tap |

The game is portrait and fully playable by touch, so the same build works on
desktop and on a phone.

## Gameplay

- **Power-ups** (blue arrow) upgrade the gun through 6 levels: 2 lanes → 5 lanes
  plus angled side shots and double damage. Taking a hit costs 2 power levels.
- **Red cross** grants an extra life, **yellow bomb** an extra bomb.
- **Waves** cycle through seven formations (line, vee, swooping stream, hovering
  helicopters, bomber flights, rocket volleys, crossing pairs) and get tougher —
  more hit points, faster planes, faster and more accurate fire.
- **Every 5th wave is a boss.** The bomber sways across the top, fires aimed
  volleys from four wing guns, and adds spread shots and radial bullet rings as
  its health drops. It catches fire as it takes damage and drops three pickups
  when it goes down. Each boss is tougher than the last.
- High score persists in `user://airstrike.cfg`.

## Layout

```
project.godot        autoloads, input map, 480x720 viewport (scaled to 640x960)
scenes/Main.tscn     the only scene: a Node2D running Main.gd
scripts/
  Art.gd    (autoload) pixel-art sprite factory: ASCII tables, procedural boss,
            ocean tiles, explosion frames
  Sfx.gd    (autoload) synthesised sound bank + a small voice pool
  G.gd      (autoload) game state, collision layers, spawn helpers
  Main.gd   game root: wave director, state flow, camera shake, screen flash
  Player.gd movement, auto-fire patterns, bombs, damage/invulnerability
  Enemy.gd  four enemy types and five movement patterns
  Boss.gd   boss phases, attacks and death sequence
  Bullet.gd Pickup.gd Explosion.gd Ocean.gd HUD.gd
```

Entities are created in code rather than as scenes, so `Main.tscn` is the single
scene file and everything else is plain GDScript.

## Android build

`export_presets.cfg` holds an Android preset (package `com.airstrike2077.game`,
arm64 + armv7, launcher icons generated from the in-game art by
`tools/make_icon.gd`). Building an APK needs a JDK, the Android SDK and Godot's
export templates; on this machine they live at:

| Piece | Path |
| --- | --- |
| JDK 17 | `/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home` |
| Android SDK | `/opt/homebrew/share/android-commandlinetools` |
| Debug keystore | `~/.android/debug.keystore` (alias `androiddebugkey`, pass `android`) |
| Export templates | `~/Library/Application Support/Godot/export_templates/4.7.stable` |

Android also requires `textures/vram_compression/import_etc2_astc=true` in
`project.godot` (already set). The tool paths are recorded in Godot's editor
settings, so a build is just:

```bash
godot --headless --path . --export-debug "Android" build/AirStrike2077.apk
```

Install it on a plugged-in phone (USB debugging enabled):

```bash
/opt/homebrew/share/android-commandlinetools/platform-tools/adb install -r build/AirStrike2077.apk
```

The debug APK is ~57 MB because it carries both architectures and debug
symbols. For a smaller build, create your own release keystore, point the
preset's `keystore/release*` fields at it and use `--export-release`.

To regenerate the launcher icons after changing the art:

```bash
godot --headless --path . --script tools/make_icon.gd
```

## Debug flags

```bash
godot --path . --auto            # hands-free autoplay (smoke test)
godot --path . --auto --boss     # jump straight to a boss at full power
SHOT_PATH=/tmp/s.png SHOT_AT=6 godot --path . --shot --peace --quit-after 20000
```

`--shot` saves a PNG at `SHOT_AT` seconds and quits; `--peace` stops the player
firing so the screen can be inspected; `--title` stays on the title screen.
