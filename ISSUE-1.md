# Issue #1: White menu

- **Link:** https://github.com/NormalCrazy000/pg_raspberry/issues/1
- **Platform:** GitHub
- **Author:** NormalCrazy000 · **Opened:** 2026-11-12
- **Labels:** none · **Assignees:** none · **Milestone:** none
- **Base branch:** origin/main @ 02fbbe3
- **Analysis date:** 2026-11-13

## Summary
The issue asks for the menu background to change from black to white. It has no comments. This is a visual change (a feature request), not a bug. The menus do not use a flat black colour. They use a dark "code editor" PNG (`#12141c` with code blended at 30% intensity), dimmed by a `modulate` of 0.65. The game field uses the same PNGs, so changing the images alone would also turn the play field white.

## Expected vs actual behavior
- **Actual:** every menu screen (main menu, character select, options, text screens, tournament) shows a dark code-editor background with light text.
- **Requested:** a white menu background.
- **Implied requirement:** all menu text and widgets must stay readable on white. Today they are light-coloured: white default font, plus `modulate` tints such as `Color(0.75, 0.8, 0.9)`.

## Steps to reproduce
Not provided. Launch the game. The boot scene leads to the main menu, which shows the dark background.

## Relevant code
- `scripts/menu/menu_style.gd:8-14`: `add_background()` adds the `TextureRect` that every menu uses as its background, with `MENU_DIM = Color(0.65, 0.65, 0.65)` at line 5. This is the single entry point for the menu background.
- `scripts/common/backgrounds.gd:15-20`: `for_menus()` picks one of the 9 language PNGs at random. `for_seed()` is also used by the game.
- `scripts/game/game.gd:189-194`: the game field uses `Backgrounds.for_seed()`, the same textures.
- `tools/assets/make_background.py:22,317-320,394-397`: generates the PNGs. `BG = "#12141c"`, the gutter colours are `#171a24` and `#232838`, and `blend()` mixes token colours with `BG` at `ALPHA = 0.30`.
- `assets/sprites/backgrounds/*.png`: the committed generated images.
- Callers of `MenuStyle.add_background`: `scripts/menu/main_menu.gd:18`, `character_select.gd:22`, `options.gd:14`, `text_screen.gd:16`, `tournament.gd:30`.
- Light text tints that would become unreadable on white:
  - `scenes/menu/main_menu.tscn:20,37` and `scenes/menu/character_select.tscn:20,37` (subtitle and hint `modulate`);
  - `scripts/menu/main_menu.gd:23` (version label);
  - `scripts/menu/tournament.gd:39,49,147`;
  - `scripts/menu/character_select.gd:58,65`;
  - `scripts/menu/bracket_view.gd:10-15` (dark boxes and light text in the bracket).
- `assets/theme.tres`: the theme only sets `default_font`. There are no colour overrides, so Labels and Buttons use Godot's default light font colour.
- `project.godot:52`: `default_clear_color = Color(0.07, 0.08, 0.12)`. It is visible wherever no background is drawn.
- `scripts/game/menu_box.gd:62-64`: the in-game pause/end menu, a dark box over the field.

## Root cause analysis
- **Verified:** the menu background is the code-editor PNG drawn by `MenuStyle.add_background`, dimmed to 65%.
- **Verified:** the game uses the same PNG set, so editing `make_background.py` / the PNGs globally would also turn the play field white.
- **Verified:** menu text relies on Godot's default (light) font colour plus light `modulate` tints. The theme defines no colours.
- **Hypothesis:** "menu" in the issue means the menu screens (`scenes/menu/*`), not the in-game `menu_box`. Confirm with the reporter.

## Proposed fix
1. **Light background assets for menus only.** Extend `tools/assets/make_background.py` with a light palette: `BG` white or near-white such as `#f7f7f5`, light grey gutter and line-number colours, and darker token colours with the same `blend()` approach. Write the output to `assets/sprites/backgrounds_light/<lang>.png`. Keep the dark set for the game.
2. In `scripts/common/backgrounds.gd`, make `for_menus()` load from the light directory, for example with a `LIGHT_DIR` constant and a small helper. `for_seed()` keeps serving the game.
3. In `scripts/menu/menu_style.gd`, remove or neutralise `MENU_DIM`. Darkening a white image makes it grey. To keep the code subtle, lower the light palette's `ALPHA` instead.
4. **Text colours.** Add to `assets/theme.tres` dark `Label/colors/font_color` and `Button/colors/font_color*` values, plus button styleboxes that look right on white. Then replace the hard-coded light `modulate` tints listed above with dark-grey equivalents. Ideally move them into named constants in `menu_style.gd`, such as `TEXT_SUBTLE` and `TEXT_HINT`, so a future theme change happens in one place.
5. Update `bracket_view.gd` constants so the tournament bracket uses light boxes, dark borders and dark text.
6. Optionally set `default_clear_color` to white so that frames without a background (e.g. during scene changes) don't flash dark. Check the game field still covers the whole screen.
7. Add a CHANGELOG entry and, if the doc describes the backgrounds, update `docs/architettura.md` (line ~49).

## Alternatives considered
- **Flat white `ColorRect` instead of a texture** in `add_background()`: smallest change, but it loses the code-editor theme. Text colours still need fixing.
- **Invert the existing PNGs at runtime** with a shader: no new assets, but the project targets GLES2 and Raspberry Pi. It gives less control over the result, and shader cost on menus is unnecessary.
- **Make the whole game light**, field included: the issue does not ask for it, the peg/ball colours were designed for a dark field, and the risk is much larger.
- **Option for light/dark menus** in the options screen: nice to have, but adds a setting. Do it only if the reporter wants both.

## Testing plan
- Regenerate the PNGs with the script and check they are committed alongside their `.import` files.
- Manually visit every menu screen in both languages (IT/EN). Check that title, subtitle, buttons (normal/focus/hover/pressed), hint, version label, character descriptions, tournament name entry and the bracket are readable.
- Navigate with keyboard and gamepad to check the focused button is still clearly visible on white.
- Start a match and confirm the game field is still dark, and that the in-game `menu_box` is unchanged unless it is in scope.
- Run `tools/smoke_test.sh` and check performance and memory on the Raspberry Pi. It loads only one background at a time, so this is probably unchanged.

## Risks and open questions
- Does "menu" include the in-game pause/end menu (`menu_box.gd`) and the tournament bracket?
- Pure white `#ffffff`, or an off-white that is easier on the eyes?
- Should the code-editor texture stay (light theme) or become a flat white?
- Plain white text on white is the main risk. Any place that relies on the default font colour or light modulates will become invisible, so all screens need a visual pass.
- Repository size grows by 9 PNGs if a light set is added.

## Estimated complexity
Medium: the background swap is small, but readable text needs colour changes across the theme and roughly six menu scripts and scenes.
