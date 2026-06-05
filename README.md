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

The canonical definitions are the HSLuv constants (`gensho-wet-hsl` / `gensho-dry-hsl`). Hex values (`gensho-wet`, `gensho-dry`) and the accessors are derived from them (respecting `gensho-hsl-correction` if non-zero).

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
  "red": "#d4647f",
  "brightred": "#bb785a",
  "yellow": "#a2835a",
  "green": "#59965e",
  "cyan": "#5f9196",
  "blue": "#638cb4",
  "brightmagenta": "#9a79c9",
  "magenta": "#cb63ae"
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
| red                 | red          | #d4647f         | #bd4f6a            |
| brightred           | orange       | #bb785a         | #a0664c            |
| yellow              | yellow       | #a2835a         | #8a704c            |
| green               | green        | #59965e         | #4b8050            |
| cyan                | cyan         | #5f9196         | #507b80            |
| blue                | blue         | #638cb4         | #54779a            |
| brightmagenta       | purple       | #9a79c9         | #8960be            |
| magenta             | magenta      | #cb63ae         | #ae5495            |

Exact values are generated from HSLuv at load time (with `gensho-hsl-correction` deltas applied if set). They are exposed via the HSL constants (`gensho-dry-hsl`, `gensho-wet-hsl`), the derived hex variables (`gensho-dry`, `gensho-wet`), and the accessors `gensho-palette` (internal semantic keys) / `gensho-export-palette` (ANSI/terminal names for external use).

For terminal emulators that want a 16-color palette, use the values from `gensho-export-palette` (or run it and copy). The 16 ANSI slots are assigned from the 16 internal colors; some "bright" slots receive gray-ramp entries because the design uses one unified 8-step mono ramp + 8 accent hues (see `gensho-export-palette` for the full mapping including aliases like brightcyan=background). 'hex-list gives the direct ordered list for slot 0-15.

## UI chrome, tab bar, and slate texture

Gensho emphasizes a quiet, layered stone aesthetic ("玄昌石") primarily through
careful assignment of the mono ramp to UI elements rather than heavy borders or
color. Key choices for "slate feel":

- **tab-bar**: The bar background uses a mid chrome layer (`mono2`). The active
  tab background matches the main editor background (`mono0`), so the selected
  view surface is continuous from the tab down into the buffer content. Inactive
  tabs use `mono1` on the bar. This produces a clean recessed selection + framing
  slab without extra boxes. Enable with `(tab-bar-mode 1)`.
- **tab-line** (per-window buffer tabs): Similar layering, slightly closer to
  content (`tab-line` at `mono1`, current at `mono0`).
- **Side panes**:
  - treemacs: The entire sidebar window gets `mono1` background
    (`treemacs-window-background-face`) so it reads as a distinct side panel.
    Directories inherit the type face (cyan); other elements stay low-key in the
    mono ramp. Git states use sparse semantic colors.
    With `vertical-border` at main mono0, the transition from the panel to the
    main editor is clean (no extra seam line), so the distinction comes from
    the tone + content. If the mono1 step from main mono0 feels strong, you can
    override the face to mono0 in your config; the panel feel will still come
    from its distinct content and the clean divider treatment.
  - dirvish (recommended dired-native alternative): `dirvish-side` gives a
    familiar dired-based pane you can drill into directories. We theme its
    hl-line and inactive faces to the ramp. Dirvish's default layouts often show
    parent + current + preview panes; the multiple vertical divisions + dividers
    naturally add visual layers that enhance the slate texture. Many users
    replace neotree/treemacs with it for tighter integration.
    **Note on background**: Dirvish re-uses ordinary dired buffers (no dedicated
    window-background face like treemacs), so the main file listing area uses
    the normal content background (`mono0`). The "side panel" feel comes from
    the header-line (already at `mono3`), hl-line (`mono2` when focused), the
    physical side window + enhanced dividers, and optional parent/preview
    columns. This is intentional given the faces dirvish exposes. If you
    strongly prefer the entire `dirvish-side` pane to have a distinct `mono1`
    background (matching the treemacs treatment), add something like this to
    your personal config:

    ```elisp
    (with-eval-after-load 'dirvish
      (add-hook 'dirvish-mode-hook
                (lambda ()
                  (when-let* ((dv (dirvish-curr))
                              ((eq (ignore-errors (dv-type dv)) 'side)))
                    (face-remap-add-relative
                     'default `(:background ,(alist-get 'mono1 (gensho-palette))))))))
    ```
- **Dividers & gutters**: `vertical-border` is set to the main content color
  (mono0). This was confirmed after direct testing to give the cleanest slate
  feel: when a side panel uses a different tone (e.g. treemacs at mono1), the
  transition to the main editor (mono0) has no visible seam line artifact.
  The distinction between areas comes from the tone difference (where used)
  + the content itself and window geometry — a common de-facto pattern for
  quiet layered looks.

  `window-divider*` (when you enable `window-divider-mode`) can still provide
  very gentle separation for regular content-to-content splits using close
  tones in the ramp. Enable with `(window-divider-mode 1)` + width vars.

  Line numbers get a quiet gutter slab.

  Note on contrast: The mono0 → mono1 step is the smallest perceptual step
  in the ramp (intentional for visible but quiet layers). If a sidebar at
  mono1 feels noticeably different from main mono0, that is expected. In that
  case it is common to keep explicit sidebars on the same mono0 as main
  content; the panel character then comes from content, hl-line, and the
  clean divider treatment. You can override `treemacs-window-background-face`
  to mono0 in your config if you prefer less contrast.

  The small L steps in the mono ramp are sufficient for subtle plane
  distinction while preserving the quiet stone aesthetic. We stay close to
  de-facto practices and do not force global bg shifts for every non-selected
  window.

  For users who want a subtle auxiliary shift for non-selected / unreal areas,
  the theme provides direct face support for the two de-facto modes that can
  consume exact palette colors:
  - `solaire-mode` (for "unreal" buffers such as sidebars/popups)
  - `auto-dim-other-buffers-mode` (for non-selected windows)

  Their dim faces are set to `mono1` (the standard first auxiliary step).
  No new colors are invented. The classic tool for a global effect remains
  those modes; our ramp + face specs make them work well with the 玄昌石
  palette while preserving the full de-facto role assignment for the 8 levels
  on main content.
- **Child frames**: Popups (corfu, transient, etc.) get consistent `mono2`
  framing via `child-frame-border`.

These are all designed so the 8-step perceptual ramp supplies the rhythm and
"stone" depth. See the design notes inside `gensho-theme.el` (the "Mono ramp"
and "Slate texture extension" comments) for the survey-derived principles.

Example to explore the effect:
```elisp
(tab-bar-mode 1)
(global-tab-line-mode 1)
(global-display-line-numbers-mode 1)
(window-divider-mode 1)
(setq window-divider-default-right-width 3)
;; then open treemacs or (dirvish-side), split windows, create tabs
```

The ramp assignments remain harmonious in both the deep "wet" and lighter
"washed-stone" "dry" variants.

## License

MIT License. See `LICENSE`.

## Credits

Original concept and implementation by yoshzucker. Structural base and modern architecture ported from rustcity-theme (https://github.com/yoshzucker/rustcity-theme). Extracted/adapted from personal dotfiles into a standalone package for the 玄昌石 aesthetic.
