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
  Returns the raw alist using the theme's internal semantic keys:
  `mono0`..`mono7` (perceptual gray ramp; `mono1` is the background and `mono7`
  the foreground for the variant, with `mono0` lying outside `mono1`, away from
  the foreground) plus the 8 accent hues `red orange yellow green cyan blue
  purple magenta`, and `dim0` / `dim1` (weak dim levels for non-selected support
  in auto-dim-other-buffers-mode / solaire-mode).

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
  "background": "#262828",
  "foreground": "#888c8c",
  "black": "#2a2c2c",
  "brightblack": "#181919",
  "brightgreen": "#353737",
  "brightyellow": "#444747",
  "brightblue": "#545757",
  "white": "#656868",
  "brightcyan": "#767a7a",
  "brightwhite": "#888c8c",
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
| brightblack         | mono0        | #181919         | #2c2e2e            |
| background          | mono1        | #262828         | #3c3d3e            |
| black               | dim0         | #2a2c2c         | #404242            |
| *(no slot)*         | dim1         | #2f3030         | #444747            |
| brightgreen         | mono2        | #353737         | #4b4e4e            |
| brightyellow        | mono3        | #444747         | #5c5e5f            |
| brightblue          | mono4        | #545757         | #6c7070            |
| white               | mono5        | #656868         | #7e8182            |
| brightcyan          | mono6        | #767a7a         | #8f9394            |
| foreground, brightwhite | mono7    | #888c8c         | #a2a6a7            |
| red                 | red          | #d4647f         | #d4647f            |
| brightred           | orange       | #bb785a         | #bb785a            |
| yellow              | yellow       | #a2835a         | #a2835a            |
| green               | green        | #59965e         | #59965e            |
| cyan                | cyan         | #5f9196         | #5f9196            |
| blue                | blue         | #638cb4         | #638cb4            |
| brightmagenta       | purple       | #9a79c9         | #9a79c9            |
| magenta             | magenta      | #cb63ae         | #cb63ae            |

The rows are in ramp order: `mono0` lies outside the background, away from the
foreground, and the dim levels sit between the background and `mono2`.

Exact values are generated from HSLuv at load time (with `gensho-hsl-correction` deltas applied if set). They are exposed via the HSL constants (`gensho-dry-hsl`, `gensho-wet-hsl`), the derived hex variables (`gensho-dry`, `gensho-wet`), and the accessors `gensho-palette` (internal semantic keys) / `gensho-export-palette` (ANSI/terminal names for external use).

For terminal emulators that want a 16-color palette, use the values from `gensho-export-palette` (or run it and copy). The background and the foreground are `mono1` and `mono7`, so they take the terminal's own background and foreground rather than a numbered slot; the sixteen slots then carry the six remaining mono levels, `dim0`, and the 8 accent hues. `brightwhite` repeats the foreground by convention, and `brightblack` holds `mono0`, the level just outside the background — the Solarized base03 role, a grey that is nearly the background, for text meant to disappear. `dim1` has no slot. `'hex-list` gives the direct ordered list for slots 0-15.

## UI chrome, tab bar, and slate texture

Gensho emphasizes a quiet, layered stone aesthetic ("玄昌石") primarily through
careful assignment of the mono ramp to UI elements rather than heavy borders or
color. The low end of the ramp says one thing only — how current a surface is:

| level   | role |
|---------|------|
| `mono0` | what is current inside the content: the line point is on, the region, the hunk you are reading |
| `mono1` | the content surface, and the figure of an active bar (current tab, mode line, header line) |
| `mono2` | what is not current: inactive bars, unselected tabs, other matches, dimmed panels |
| `mono3` | the ground a bar is drawn on: tab-bar and tab-line fields, tooltips, child-frame rims |

Key choices for "slate feel":

- **Highlights recess**: `hl-line`, `region` and the current diff hunk take
  `mono0`, which lies *outside* the background rather than a step toward the
  foreground. The highlighted row therefore reads as cut into the slate, and its
  text gains contrast rather than losing it. Most themes move a highlight the
  other way; gensho keeps the background one step in from the end of the ramp
  precisely so this direction is available.
- **tab-bar**: The bar itself is drawn on the outer ground (`mono3`). The current
  tab takes `mono1`, the content surface, so the selected view is continuous from
  the tab down into the buffer. The other tabs rise to `mono2`, the plane every
  idle surface takes. Enable with `(tab-bar-mode 1)`.
- **tab-line** (per-window buffer tabs): the same three levels, so the two bars
  read as one object in two positions.
- **Side panes**:
  - treemacs: The entire sidebar window gets the `mono2` background
    (`treemacs-window-background-face`) so it reads as a distinct side panel.
    Directories inherit the type face (cyan); other elements stay low-key in the
    mono ramp. Git states use sparse semantic colors.
    With `vertical-border` at `mono1`, the transition from the panel to the
    main editor is clean (no extra seam line), so the distinction comes from
    the tone + content. If the step feels strong, you can override the face to
    `mono1` in your config; the panel feel will still come from its distinct
    content and the clean divider treatment.
  - dirvish (recommended dired-native alternative): `dirvish-side` gives a
    familiar dired-based pane you can drill into directories. We theme its
    hl-line and inactive faces to the ramp. Dirvish's default layouts often show
    parent + current + preview panes; the multiple vertical divisions + dividers
    naturally add visual layers that enhance the slate texture. Many users
    replace neotree/treemacs with it for tighter integration.
    **Note on background**: Dirvish re-uses ordinary dired buffers (no dedicated
    window-background face like treemacs), so the main file listing area uses
    the normal content background (`mono1`). The "side panel" feel comes from
    its hl-line (`mono0` when focused, `mono2` when not), the physical side
    window + enhanced dividers, and optional parent/preview columns. This is
    intentional given the faces dirvish exposes. If you strongly prefer the
    entire `dirvish-side` pane to have a distinct `mono2` background (matching
    the treemacs treatment), add something like this to your personal config:

    ```elisp
    (with-eval-after-load 'dirvish
      (add-hook 'dirvish-mode-hook
                (lambda ()
                  (when-let* ((dv (dirvish-curr))
                              ((eq (ignore-errors (dv-type dv)) 'side)))
                    (face-remap-add-relative
                     'default `(:background ,(alist-get 'mono2 (gensho-palette))))))))
    ```
- **dired-subtree**: The package ships six hard-coded backgrounds of its own,
  so an expanded listing would arrive in tones the rest of the frame never
  uses. It asks for six background planes; the ramp has two to spare
  (`mono1` for content, `mono2` for the idle step on top of it), and spending
  `mono3` here would put a file listing at tab-bar brightness while `mono0`
  would claim the level that means "current". The background therefore carries the one thing it is needed for
  — where an expanded block begins and ends — and the two planes alternate, so
  each nesting sits on the other plane from the block holding it. Absolute
  depth is carried by the indentation. Set `dired-subtree-use-backgrounds` to
  nil if you would rather have no planes at all.
- **Dividers & gutters**: `vertical-border` is set to the content color
  (`mono1`), which gives the cleanest slate feel: when a side panel uses a
  different tone (e.g. treemacs at `mono2`), the transition to the main editor
  has no visible seam line artifact. The distinction between areas comes from
  the tone difference (where used) + the content itself and window geometry —
  a common de-facto pattern for quiet layered looks.

  `window-divider*` (when you enable `window-divider-mode`) can still provide
  very gentle separation for regular content-to-content splits using close
  tones in the ramp. Enable with `(window-divider-mode 1)` + width vars.

  Line numbers get a quiet gutter slab.

  Note on contrast: the ramp is evenly spaced, so a sidebar at `mono2` is a
  full step away from the content at `mono1` and is meant to be visible. If
  that reads as too much, it is common to keep explicit sidebars on the same
  level as the content; the panel character then comes from content, hl-line,
  and the clean divider treatment. Override `treemacs-window-background-face`
  to `mono1` in your config if you prefer less contrast.

  The small L steps in the mono ramp are sufficient for subtle plane
  distinction while preserving the quiet stone aesthetic. We stay close to
  de-facto practices and do not force global bg shifts for every non-selected
  window.

  For users who want a subtle auxiliary shift for non-selected / unreal areas,
  the theme provides direct face support for the two de-facto modes that can
  consume exact palette colors:
  - `solaire-mode` (for "unreal" buffers such as sidebars/popups)
  - `auto-dim-other-buffers-mode` (for non-selected windows)

  Their dim faces are set to `dim0`, a dedicated level that shifts the content
  background by less than a full step of the main ramp. This allows a weaker
  "ほんの少し" shift for non-selected areas while leaving the 8-step mono ramp
  and its roles untouched. `dim1` is a second such level, available for
  customization. No colors outside the published structure are invented.
  The classic tool for a global effect remains those modes; our ramp + face
  specs make them work well with the 玄昌石 palette.
- **Child frames**: Popups (corfu, transient, etc.) get consistent `mono3`
  framing via `child-frame-border`, the same ground the bars are drawn on.

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
