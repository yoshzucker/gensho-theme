# gensho-theme

A dual light/dark Emacs theme inspired by 玄昌石 (Genshō stone) — a deep, elegant black stone with subtle texture and quiet presence.

## Installation

### straight.el + use-package (recommended)

```elisp
(use-package gensho-theme
  :straight (:host github :repo "yoshzucker/gensho-theme")
  :config
  (setq frame-background-mode 'dark)   ; or 'light
  (load-theme 'gensho t))
```

### Manual

Clone the repository and add its directory to your `load-path`, then:

```elisp
(setq frame-background-mode 'dark)   ; or 'light
(load-theme 'gensho t)
```

### Switching variants

The theme reads `frame-background-mode` at load time. To change between `wet` (deeper dark variant) and `dry` (lighter washed-stone variant) after the theme is already loaded, disable it and reload with the desired value:

```elisp
(disable-theme 'gensho)
(setq frame-background-mode 'light)   ; or 'dark  (light -> dry, dark -> wet)
(load-theme 'gensho t)
```

## Using the palette

After loading the package (or the theme), the palette is available in two ways:

- Inside Emacs (e.g. for additional custom faces in your config or special setups):
  ```elisp
  (gensho-palette)        ; current variant based on frame-background-mode
  (gensho-palette 'wet)   ; or 'dry
  ```
  Returns the raw alist of 16 entries using the theme's internal semantic keys:
  `mono0`..`mono7` (perceptual gray ramp; `mono0` is the background, `mono7` the
  foreground for the variant) plus the 8 accent hues `red orange yellow green cyan
  blue purple magenta`.

- For external tools (Alacritty, kitty, WezTerm, ghostty, dircolors, terminal OSC
  sequences, etc.):
  ```elisp
  (gensho-export-palette 'json 'wet)
  (gensho-export-palette 'alist 'dry)
  (gensho-export-palette 'hex-list)
  ```
  'json and 'alist use conventional ANSI/terminal color names (`background`,
  `foreground`, `black`, `red`, ..., `brightwhite`) so the data is directly usable
  in terminal configs. 'hex-list returns exactly 16 hex values in the ANSI 0-15
  slot order chosen for this palette.

  **Note**: `gensho-export-palette 'alist` returns an alist with ANSI keys (for consistency with rustcity-theme).

The canonical definitions are the HSLuv constants (`gensho-wet-hsl` / `gensho-dry-hsl`). Hex values (`gensho-wet`, `gensho-dry`) and the accessors are derived from them.

Example JSON (via `gensho-export-palette 'json 'wet`):
```json
{
  "background": "#1e1f1f",
  "brightcyan": "#1e1f1f",
  "black": "#2c2e2e",
  "brightblack": "#3c3d3e",
  "brightblue": "#4b4e4e",
  "brightgreen": "#5c5e5f",
  "white": "#6c7070",
  "brightyellow": "#7e8182",
  "foreground": "#8f9394",
  "brightwhite": "#8f9394",
  "red": "#fe5384",
  "brightred": "#e67300",
  "yellow": "#b78d00",
  "green": "#4fa600",
  "cyan": "#00a2b4",
  "blue": "#0c96ff",
  "brightmagenta": "#cd63ff",
  "magenta": "#fe36de"
}
```

(The `wet` variant is the deeper dark; use `'dry` for the washed-stone lighter dark variant.)

## Palette overview + terminal mapping

| Role / ANSI key     | Internal key | wet (deep dark) | dry (washed stone) |
|---------------------|--------------|-----------------|--------------------|
| background, brightcyan | mono0     | #1e1f1f         | #3c3d3e            |
| black               | mono1        | #2c2e2e         | #444747            |
| brightblack         | mono2        | #3c3d3e         | #4e5050            |
| brightblue          | mono3        | #4b4e4e         | #57595a            |
| brightgreen         | mono4        | #5c5e5f         | #606363            |
| white               | mono5        | #6c7070         | #6a6d6d            |
| brightyellow        | mono6        | #7e8182         | #747777            |
| foreground, brightwhite | mono7   | #8f9394         | #7e8182            |
| red                 | red          | #fe5384         | #fc006d            |
| brightred           | orange       | #e67300         | #cb6400            |
| yellow              | yellow       | #b78d00         | #967f00            |
| green               | green        | #4fa600         | #449200            |
| cyan                | cyan         | #00a2b4         | #008e9e            |
| blue                | blue         | #0c96ff         | #0083e1            |
| brightmagenta       | purple       | #cd63ff         | #c735ff            |
| magenta             | magenta      | #fe36de         | #ea00cb            |

Exact values are generated from HSLuv at load time. They are exposed via the HSL constants (`gensho-dry-hsl`, `gensho-wet-hsl`), the derived hex constants (`gensho-dry`, `gensho-wet`), and the accessors `gensho-palette` (internal semantic keys) / `gensho-export-palette` (ANSI/terminal names for external use).

For terminal emulators that want a 16-color palette, use the values from `gensho-export-palette` (or run it and copy). The 16 ANSI slots are assigned from the 16 internal colors; some "bright" slots receive gray-ramp entries because the design uses one unified 8-step mono ramp + 8 saturated accent hues (see `gensho-export-palette` for the full mapping including aliases like brightcyan=background). 'hex-list gives the direct ordered list for slot 0-15.

## License

MIT License. See `LICENSE`.

## Credits

Original concept and implementation by yoshzucker. Structural base and modern architecture ported from rustcity-theme (https://github.com/yoshzucker/rustcity-theme). Extracted/adapted from personal dotfiles into a standalone package for the 玄昌石 aesthetic.
