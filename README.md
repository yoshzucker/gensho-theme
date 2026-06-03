# gensho-theme

A dual light/dark Emacs theme inspired by 玄昌石 (Genshō stone) — a deep, elegant black stone with subtle texture and quiet presence.

- **neon** (dark): Deep, refined darkness evoking the dignified quiet of Genshō stone under night. Strong atmospheric tone with perceptual clarity.
- **downpour** (light): A washed, pale stone in overcast daylight — subtle, calm, and highly readable.

The theme is built on perceptual HSLuv colors for hue and lightness consistency. It aims for readability while keeping a strong atmospheric tone. (This is a structural port of the latest rustcity-theme architecture; the color palette itself is actively refined for the stone aesthetic.)

This is a personal theme. The color palette is being actively tuned.

> **Note**: Expect palette changes. When using from dotfiles with straight.el, pin to a specific commit or branch for stability.

## Installation

### straight.el + use-package (recommended)

```elisp
(use-package gensho-theme
  :straight (:host github :repo "yoshzucker/gensho-theme")
  :config
  (setq frame-background-mode 'dark)   ; or 'light
  (load-theme 'gensho t))
```

(For active development work you can add `:branch "develop"` as before.)

### Manual

Clone the repository and add its directory to your `load-path`, then:

```elisp
(setq frame-background-mode 'dark)   ; or 'light
(load-theme 'gensho t)
```

### Switching variants

The theme reads `frame-background-mode` at load time. To change between `neon` and `downpour` after the theme is already loaded, disable it and reload with the desired value:

```elisp
(disable-theme 'gensho)
(setq frame-background-mode 'light)   ; or 'dark
(load-theme 'gensho t)
```

## Using the palette

After loading the package (or the theme), the palette is available in two ways:

- Inside Emacs (e.g. for additional custom faces in your config or special setups):
  ```elisp
  (gensho-palette)        ; current variant based on frame-background-mode
  (gensho-palette 'neon)
  ```
  Returns the raw alist of 16 entries using the theme's internal semantic keys:
  `mono0`..`mono7` (perceptual gray ramp; `mono0` is the background, `mono7` the
  foreground for the variant) plus the 8 accent hues `red orange yellow green cyan
  blue purple magenta`.

- For external tools (Alacritty, kitty, WezTerm, ghostty, dircolors, terminal OSC
  sequences, etc.):
  ```elisp
  (gensho-export-palette 'json 'neon)
  (gensho-export-palette 'alist 'downpour)
  (gensho-export-palette 'hex-list)
  ```
  'json and 'alist use conventional ANSI/terminal color names (`background`,
  `foreground`, `black`, `red`, ..., `brightwhite`) so the data is directly usable
  in terminal configs. 'hex-list returns exactly 16 hex values in the ANSI 0-15
  slot order chosen for this palette.

  **Note**: `gensho-export-palette 'alist` now returns an alist with ANSI keys (behavior change from pre-port gensho for consistency with rustcity).

The canonical definitions are the HSLuv constants (`gensho-*-hsl`). Hex values and the alist accessors are derived from them.

Example JSON (truncated, neon variant, via `gensho-export-palette 'json 'neon`):
```json
{
  "background": "#192141",
  "foreground": "#8995d1",
  "black": "#253058",
  "red": "#fe608a",
  "green": "#73a700",
  "yellow": "#b19600",
  "blue": "#359bff",
  "magenta": "#fe3ef8",
  "cyan": "#00a9b1",
  "white": "#5c6fbe",
  ...
  "brightwhite": "#8995d1"
}
```

## Palette overview + terminal mapping

| Role / ANSI key | Internal key | neon (dark) | downpour (light)          |
|-----------------|--------------|-------------|---------------------------|
| background      | mono0        | deep stone night | pale washed stone        |
| foreground      | mono7        | cool stone lavender | dark stone gray        |
| black           | mono1        | ...         | ...                       |
| brightred       | orange       | ...         | ...                       |
| ... (see export) | ...       | ...         | ...                       |

Exact values are generated from HSLuv at load time. They are exposed via the HSL constants, the derived hex constants (`gensho-neon`, `gensho-downpour`), and the accessors `gensho-palette` (internal semantic keys) / `gensho-export-palette` (ANSI/terminal names for external use).

For terminal emulators that want a 16-color palette, use the values from `gensho-export-palette` (or run it and copy). The 16 ANSI slots are assigned from the 16 internal colors; some "bright" slots receive gray-ramp entries because the design uses one unified 8-step mono ramp + 8 saturated accent hues. 'hex-list gives the direct ordered list for slot 0-15.

## License

MIT License. See `LICENSE`.

## Credits

Original concept and implementation by yoshzucker. Structural base and modern architecture ported from rustcity-theme (https://github.com/yoshzucker/rustcity-theme). Extracted/adapted from personal dotfiles into a standalone package for the 玄昌石 aesthetic.
