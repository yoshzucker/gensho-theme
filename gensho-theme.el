;;; gensho-theme.el --- Gensho theme: dark elegance of 玄昌石 -*- lexical-binding: t; -*-

;; Author: yoshzucker
;; Maintainer: yoshzucker
;; Version: 0.1.0
;; Package-Requires: ((emacs "27.1") (hsluv "1.0"))
;; Keywords: faces, themes, gensho, stone, dark
;; Homepage: https://github.com/yoshzucker/gensho-theme
;; License: MIT

;;; Commentary:

;; Dual light/dark theme using HSLuv colors.
;;
;; Usage (standalone):
;;   (setq frame-background-mode 'dark)   ; or 'light
;;   (load-theme 'gensho t)
;;
;; Or with straight/use-package:
;;   (use-package gensho-theme
;;     :straight (:host github :repo "yoshzucker/gensho-theme")
;;     :config
;;     (setq frame-background-mode 'dark)
;;     (load-theme 'gensho t))
;;
;; Programmatic palette access:
;;   (gensho-palette)        ; internal semantic keys (mono0-7 + 8 hues)
;;   (gensho-export-palette 'json 'wet)  ; ANSI/terminal names for external tools
;;
;; Display compensation:
;;   (setq gensho-hsl-correction '(0.0 0.0 -1.5))  ; e.g. darken L a bit
;;   (gensho-apply-hsl-correction)                 ; then reloads theme if active
;; See the defcustom docstring for details and caveats (linear approx.).
;;
;; Optional dimming modes:
;;   Gensho provides face specs for `solaire-mode' (unreal buffers) and
;;   `auto-dim-other-buffers-mode' (non-selected windows) and reserves
;;   palette steps (`dim0' / `dim1') for them.  These modes are not
;;   enabled by the theme; the user opts in by enabling the mode in
;;   their config.  When enabled, gensho's pre-bound dim faces take
;;   effect with no further configuration.
;;
;; Magit faces are included and follow the theme's mono ramp + limited accents
;; (with heavy use of :inherit) so that highlights/headers harmonize even in the
;; non-standard "light" (dry) variant, which uses dark bg + light text.

;;; Code:

(require 'hsluv)
(require 'cl-lib)

(deftheme gensho
  "A dual light/dark theme inspired by 玄昌石 (Genshō stone) — dark elegance with a quiet, washed-stone light variant.")

;; Accent HSL tuning.
;; See the detailed "Accent colors (hues)" design notes below for the full
;; general (PCCS/色彩検定 hue-diff + harmony principles + UI practice,
;; applicable to any theme) and gensho-specific (PCCS 類似色相配色 cool
;; dominant + limited 中差/対照 warm seasonal cluster + なじみ原理 for
;; rotenburo reflections on cool stone bg h~200; not pure geometric)
;; strategy.  Base now uses s=55 (微増 after additional de-facto-respecting
;; freq reductions in minibuffer/org/dired to address clutter/noise in
;; completion, rich org buffers, and file info like permissions) + l slightly
;; below fg; if frequency is further reduced, s (and optionally l) can
;; increase for more vividness while preserving stone dominance.  Current h
;; chosen for natural "映り込む" elements (petals, momiji, light, sky) +
;; de-facto semantics. Additional reductions (e.g. orderless to cool cluster,
;; dired-perm-write to mono4) keep core semantics intact.
(defconst gensho-dry-hsl
  '((mono0   . (200   5  26))
    (dim0    . (200   5  28))   ; dedicated dim level for non-selected (weaker than mono1 aux)
    (dim1    . (200   5  30))
    (mono1   . (200   5  32))
    (mono2   . (200   5  38))
    (mono3   . (200   5  44))
    (mono4   . (200   5  50))
    (mono5   . (200   5  56))
    (mono6   . (200   5  62))
    (mono7   . (200   5  68))
    (red     . (  0  55  57))
    (orange  . ( 30  55  57))
    (yellow  . ( 55  55  57))
    (green   . (130  55  57))
    (cyan    . (202  55  57))
    (blue    . (242  55  57))
    (purple  . (280  55  57))
    (magenta . (325  55  57))))

(defconst gensho-wet-hsl
  '((mono0   . (200   5  16))
    (dim0    . (200   5  18))   ; dedicated dim level for non-selected (weaker than mono1 aux)
    (dim1    . (200   5  20))
    (mono1   . (200   5  22))
    (mono2   . (200   5  28))
    (mono3   . (200   5  34))
    (mono4   . (200   5  40))
    (mono5   . (200   5  46))
    (mono6   . (200   5  52))
    (mono7   . (200   5  58))
    (red     . (  0  55  57))
    (orange  . ( 30  55  57))
    (yellow  . ( 55  55  57))
    (green   . (130  55  57))
    (cyan    . (202  55  57))
    (blue    . (242  55  57))
    (purple  . (280  55  57))
    (magenta . (325  55  57))))

(defcustom gensho-hsl-correction '(0.0 0.0 0.0)
  "HSLuv deltas (h s l) added to every base color before hex conversion.

Intended to compensate for display characteristic differences (e.g.
perceived darkness of the wet variant mono0 background on some
setups vs. others).  The correction is applied uniformly and
linearly in HSLuv space to all 16 palette entries (mono0-7 and the
8 hues) for both wet and dry variants.

Because the relationship between HSLuv values and actual display
response may not be perfectly linear, a single set of deltas is a
first-order approximation.  Small L adjustments are often most
effective for background lightness; large corrections can affect
ramp spacing or accent distinguishability.  Always verify visually
after changing, and prefer the smallest effective values.

The canonical design values remain in `gensho-dry-hsl' and
`gensho-wet-hsl'\; this option only affects derived hex palettes.

Set the value before loading the theme, or call
`gensho-apply-hsl-correction' afterwards (and reload the theme if
necessary)."
  :type '(list float float float)
  :group 'gensho-theme
  :set (lambda (sym val)
         (set-default sym val)
         (when (fboundp 'gensho--recompute-derived-palettes)
           (gensho--recompute-derived-palettes))))

;; HSL correction helpers (after defcustom so the variable is known).
(defun gensho--correct-hsl (hsl)
  "Add `gensho-hsl-correction' deltas to HSL (h s l) list.
Uses cl-destructuring-bind for clarity (cl-lib is already required
and cl-loop is used elsewhere with the cl- prefix)."
  (cl-destructuring-bind (h s l) hsl
    (cl-destructuring-bind (dh ds dl) gensho-hsl-correction
      (list (mod (+ h dh) 360.0)
            (max 0.0 (min 100.0 (+ s ds)))
            (max 0.0 (min 100.0 (+ l dl)))))))

(defun gensho--hex-palette (hsl-palette)
  "Convert HSL alist to hex alist using `hsluv-hsluv-to-hex'.
Respects the current value of `gensho-hsl-correction'."
  (cl-loop for entry in hsl-palette
           for name = (car entry)
           for hsl = (gensho--correct-hsl (cdr entry))
           collect `(,name . ,(hsluv-hsluv-to-hex hsl))))

(defvar gensho-dry nil
  "Derived hex palette for the dry (light/washed-stone) variant.
Computed from `gensho-dry-hsl' + `gensho-hsl-correction'.")

(defvar gensho-wet nil
  "Derived hex palette for the wet (dark) variant.
Computed from `gensho-wet-hsl' + `gensho-hsl-correction'.")

(defun gensho--recompute-derived-palettes ()
  "Recompute `gensho-dry' and `gensho-wet' from HSL bases + correction."
  (setq gensho-dry (gensho--hex-palette gensho-dry-hsl)
        gensho-wet (gensho--hex-palette gensho-wet-hsl)))

;; Initial computation (after defcustom and helpers are defined).
(gensho--recompute-derived-palettes)

;;;###autoload
(defun gensho-palette (&optional variant)
  "Return hex color alist for VARIANT or current `frame-background-mode'.
VARIANT is `wet' or `dry' (defaults from `frame-background-mode').

The alist uses the theme's internal semantic palette keys:
  mono0..mono7  (perceptual gray ramp for main content; mono0 is background,
                 mono7 foreground for the chosen variant; de-facto roles:
                 mono1 for subtle selection/highlight on main, etc.)
  dim0, dim1    (dedicated dim levels between mono0 and mono1, for the base
                 background of non-selected/unreal areas when using the
                 supported modes auto-dim-other-buffers-mode or solaire-mode.
                 Allows weaker dim than the standard aux step at mono1 while
                 preserving the 8-step mono semantics for content.)
  red orange yellow green cyan blue purple magenta  (accent hues)

The returned colors respect `gensho-hsl-correction' (if non-zero).
For external tools / terminal emulators prefer `gensho-export-palette',
which maps to conventional ANSI/terminal color names (background, black,
brightblack, ...). The dim* levels are internal to Emacs UI and not
included in the 16-color export."
  (let ((v (or variant
               (if (eq frame-background-mode 'light) 'dry 'wet))))
    (if (eq v 'dry) gensho-dry gensho-wet)))

(let* ((class '((class color) (min-colors 89)))
       (colors (gensho-palette))
       (mono0  (alist-get 'mono0 colors))
       (mono1  (alist-get 'mono1 colors))
       (mono2  (alist-get 'mono2 colors))
       (mono3  (alist-get 'mono3 colors))
       (mono4  (alist-get 'mono4 colors))
       (mono5  (alist-get 'mono5 colors))
       (mono6  (alist-get 'mono6 colors))
       (mono7  (alist-get 'mono7 colors))
       (dim0   (alist-get 'dim0 colors))
       (dim1   (alist-get 'dim1 colors))
       (red    (alist-get 'red colors))
       (orange (alist-get 'orange colors))
       (yellow (alist-get 'yellow colors))
       (green  (alist-get 'green colors))
       (cyan   (alist-get 'cyan colors))
       (blue   (alist-get 'blue colors))
       (purple (alist-get 'purple colors))
       (magenta (alist-get 'magenta colors)))

  ;; Design notes distilled from surveys of other themes (catppuccin, nord,
  ;; solarized, zenburn, modus, gruvbox, and similar). These record general
  ;; patterns and derived principles that can inform the design of *any* theme.
  ;; Gensho's palette definitions and face settings (below) are one concrete
  ;; application of them.

  ;; Mono ramp (perceptual lightness steps)
  ;;
  ;; Surveys of many themes reveal a clear, consistent pattern for gray ramps
  ;; used to establish visual hierarchy and a layered background texture.
  ;; Importantly, the assignment of meaning to the (typically ~8) steps of
  ;; such a ramp is itself part of the general, survey-derived knowledge:
  ;;
  ;; - A perceptual ramp (typically 6-9 steps, often computed via HSLuv or
  ;;   similar for uniform lightness) provides the foundation. The steps create
  ;;   a subtle stacked layering that remains visible even when syntax colors
  ;;   and UI elements are present.
  ;; - Related chrome elements are assigned *adjacent* steps on the ramp. This
  ;;   preserves the coherence of the layering (e.g. an active bar is one step
  ;;   "above" its inactive counterpart).
  ;; - A clear, recurring pattern is the assignment of semantic roles to an
  ;;   8-step (or similar) perceptual gray ramp. This assignment of "what each
  ;;   of the 8 levels means" is itself a general fact derived from surveys,
  ;;   not specific to any one theme:
  ;;     step ~0 (lowest): main background; also used as foreground for
  ;;                       high-attention pop elements that sit on colored
  ;;                       backgrounds.
  ;;     step ~1 (next):   subtle backgrounds for selection, current item,
  ;;                       highlights, matching regions, etc. (the standard
  ;;                       de-facto aux step on main content).
  ;;                       Dedicated dim levels (dim0/dim1, between mono0 and
  ;;                       this step) are provided for the supported modes'
  ;;                       non-selected/unreal faces, so dim can be weaker than
  ;;                       the main aux while preserving the 8-step semantics
  ;;                       for content.
  ;;     step ~2-3:        alt / medium subtle (active chrome bg, some
  ;;                       highlights).
  ;;     step ~4 (mid-low): faint / secondary (shadow, doc-face, low-
  ;;                       priority or weekend indicators).
  ;;     step ~5 (mid):    comments and other secondary / low-weight text
  ;;                       and UI elements.
  ;;     step ~6 (high-mid): prominent secondary (cursor bg, minibuffer
  ;;                         prompt, current completion item text, inactive
  ;;                         chrome fg, variables/identifiers as the most
  ;;                         frequent text, etc.).
  ;;     step ~7 (highest): primary / main foreground (default text,
  ;;                        active chrome text, etc.).
  ;;   (The exact numbering and lightness deltas are implementation
  ;;   details; the *role assignment to the 8 levels* is the survey-derived
  ;;   universal pattern.)
  ;; - The overall derived principle: the gray ramp layers supply the primary
  ;;   visual rhythm; color is used as accent on top of this foundation.

  ;; Slate texture extension (gensho-specific application of the above):
  ;; To evoke 玄昌石 (layered, quiet stone) despite Emacs' sparse chrome,
  ;; we deliberately map UI structural elements to adjacent ramp steps.
  ;; The main content plane is at mono0. Explicit auxiliary panels (such as
  ;; the treemacs sidebar) use the next step (mono1) via their dedicated faces
  ;; for a subtle layered "stone slab" effect.
  ;;
  ;; For the divider between such a panel and the main content, we set it to
  ;; the main content color (mono0). This produces a clean transition without
  ;; a visible seam line that would fight the plane expression — the
  ;; distinction comes from the tone difference (where present) and the
  ;; content itself. This choice was confirmed to give good slate feel after
  ;; direct testing.
  ;;
  ;; We keep normal editing buffers on the main mono0 plane. The main de-facto
  ;; signal for non-active windows is `mode-line-inactive` (set to mono1 here,
  ;; providing a gentle auxiliary-layer treatment at the chrome level).
  ;; For users who want a global subtle shift for non-selected windows
  ;; or unreal buffers, we provide explicit face support for the two de-facto
  ;; modes that can use exact palette colors without inventing new ones:
  ;; solaire-mode (for "unreal" buffers) and auto-dim-other-buffers-mode (for
  ;; non-selected windows). Their dim faces are set to dim0 (a dedicated level
  ;; between mono0 and the standard aux mono1), so enabling the mode gives a
  ;; weaker aux tone while preserving the full de-facto role assignment for
  ;; the main 8 levels (subtle at mono1 etc.) on content. dim1 is also
  ;; available for customization.
  ;;
  ;; Chrome direction -- walled / sunken / ha-ha
  ;; (garden architecture metaphor)
  ;;
  ;; Three patterns coexist for chrome elements (mode-line, tab-bar,
  ;; tab-line) that sit alongside the body.  The metaphor comes from
  ;; garden architecture: the "garden floor" is body bg (the active
  ;; editing surface) and the surroundings are chrome bg.
  ;;
  ;;   Walled: active chrome FAR from body in the fg direction (tall
  ;;     wall); inactive chrome closer to body.  The active focus
  ;;     area is surrounded by tall walls that make it stand out.
  ;;
  ;;   Sunken: active chrome at body level; inactive chrome moves
  ;;     slightly TOWARD fg from body.  The active focused window
  ;;     reads as the sunken floor; inactive surroundings rise as
  ;;     walls on the fg-facing side.
  ;;
  ;;   Ha-ha (sunken fence): active chrome at or near body level;
  ;;     inactive chrome moves AWAY FROM fg from body (into a ditch
  ;;     on the anti-fg side).  The focus area sits on garden level
  ;;     while the surrounding chrome lies in a recessed ditch.
  ;;
  ;; "Toward fg" and "anti-fg" are direction-agnostic on the brightness
  ;; ramp.  For themes where fg is brighter than bg (gensho and most
  ;; dark themes), toward fg = brighter, anti-fg = darker.  For typical
  ;; light themes (bg brighter than fg), toward fg = darker, anti-fg
  ;; = brighter.  The semantic (active position vs inactive position
  ;; relative to body and fg) is what matters; absolute brightness
  ;; depends on the theme's bg/fg relationship.
  ;;
  ;; Whether a theme can express all three patterns depends on its
  ;; palette geometry: if body bg sits at an extreme of the ramp
  ;; (e.g. pure white in Modus operandi, pure black in Modus vivendi,
  ;; or the darkest entry like gensho's mono0), the anti-fg direction
  ;; has no palette room, so ha-ha is not available -- only walled
  ;; or sunken.
  ;;
  ;; Survey (source inspection, body-distance + fg-direction analysis):
  ;;
  ;;   Theme               | mode-line | tab-bar
  ;;   --------------------+-----------+--------
  ;;   Modus operandi/viv. | walled    | sunken
  ;;   Catppuccin mocha    | ha-ha     | walled
  ;;   Catppuccin latte    | sunken    | walled
  ;;   Doom one dark       | ha-ha     | ha-ha
  ;;   Doom one light      | sunken    | sunken
  ;;
  ;; All three patterns are in active use.  The same design intent
  ;; can classify differently between a theme's light and dark
  ;; variants (Doom one and Catppuccin's mode-line) because the bg/fg
  ;; direction flips while the chrome's palette direction stays
  ;; fixed.  Themes with body bg at a brightness extreme (Modus) can
  ;; only express walled or sunken (no ha-ha possible).
  ;;
  ;; The pattern interacts with the theme's "dim direction" -- where
  ;; body bg shifts when a non-active window is dimmed (by solaire /
  ;; auto-dim-other-buffers, or any equivalent mode), and whether
  ;; that direction is toward fg or anti-fg:
  ;;
  ;;   - dim toward fg (gensho's wet/dry both: mono0 -> dim0 brighter,
  ;;     which is the fg direction since gensho has fg > bg):
  ;;     sunken keeps all "active" elements (body, mode-line, selected
  ;;     tab) at the same body-bg stratum, with dim'd bodies and
  ;;     inactive chrome rising slightly toward fg as a coherent unit.
  ;;     Walled or ha-ha would split "active" across strata.
  ;;
  ;;   - dim anti-fg: active body sits on the fg side of dim'd body.
  ;;     Walled or ha-ha (active chrome aligned with active body)
  ;;     would keep "active" coherent; sunken would split it.
  ;;
  ;; This is orthogonal to whether any dimming mode is actually
  ;; enabled -- the principle applies to the static palette geometry.
  ;;
  ;; This theme commits to fully sunken: `mode-line', `tab-bar-tab'
  ;; and `tab-line-tab-current' bg = mono0 (= active body).  The
  ;; active window's chrome is visually flush with the editing
  ;; surface; the inactive window gets a visible mono1 bar.  Among
  ;; surveyed themes, the closest match is Doom one light (also
  ;; fully sunken).
  ;;
  ;; Gensho commits to fully sunken because its dim direction is
  ;; "toward fg" in both variants (mono0 -> dim0 brighter, which is
  ;; the fg direction since gensho has fg > bg in both wet and dry).
  ;; Sunken keeps all "active" elements bottoming out at one stratum.
  ;; Aesthetically, the body-level chrome evokes the 玄昌石 (Genshō
  ;; stone) slate recess.

  ;; Accent colors (hues)
  ;;
  ;; A. Observed convergence on semantic mappings
  ;;    Across the surveyed themes there is strong agreement on hue choices for
  ;;    common semantic roles (chosen for harmony, distinguishability, and
  ;;    modern "feel"):
  ;;    - Strings/literals: green (positive, harmonious; dominant modern
  ;;      choice).
  ;;    - Keywords and control flow: purple or mauve.
  ;;    - Builtins: red or orange-red (pairs with error).
  ;;    - Functions and calls: often magenta or a blue/magenta family member.
  ;;    - Types: cyan or blue (provides structure with low pop).
  ;;    - Constants: frequently a blue or near-background hue (avoids over-use
  ;;      of warm complements).
  ;;    - Warnings/alerts: yellow (kept distinct from error red).
  ;;    - Errors: red (near-universal); success/DONE states: green.
  ;;
  ;; B. Strategies for choosing specific hues against a tinted background
  ;;    When the background itself carries a hue (even a very low-saturation
  ;;    one), two broad strategies are observable:
  ;;    - Analogous / cool-bias: select accent hues close to the background's
  ;;      own hue. This favors calm, harmony, and lets low-saturation gray
  ;;      layers stay prominent (seen in solarized cool variants, nord, many
  ;;      "slate" or muted dark themes).
  ;;    - Complementary / higher-pop: make greater use of opposing or warmer
  ;;      hues for stronger vibrancy and immediate visual distinction.
  ;;
  ;; C. Principles shared by both strategies
  ;;    - Strictly limit the number of distinct hues present in any single
  ;;      buffer or major UI component.
  ;;    - Rely heavily on the mono gray ramp plus `:inherit` for the majority
  ;;      of faces (outlines, directory faces, titles, etc.) so that hue noise
  ;;      does not overwhelm the gray foundation.
  ;;    - Reserve the most saturated, attention-grabbing hues for short-lived,
  ;;      interactive or transient overlays only (isearch, tooltips, avy
  ;;      leads, orderless match highlights, etc.). Persistent syntax and
  ;;      structural elements stay within the gray ramp or the limited
  ;;      semantic hues.
  ;;
  ;; D. Other recurring tendencies
  ;;    - Links often use a cool hue (blue) to differentiate navigation from
  ;;      the green used for strings.
  ;;    - Org/Magit/Agenda and similar rich modes inherit the font-lock and
  ;;      mono decisions heavily; hues are introduced only for key status
  ;;      indicators (TODO, DONE). Secondary or historical information (past
  ;;      scheduled, weekend dates, etc.) stays in the gray ramp.
  ;;    - Tables, dates, and calendar elements commonly inherit from the type
  ;;      face (cyan/blue) or fall back to mono.

  ;; Gensho follows the analogous/cool-bias strategy for its accent hues. Its
  ;; backgrounds are low-saturation blue-tinted grays (hue ~200), and the
  ;; design places primary emphasis on the dominance of the mono gray layers
  ;; over high-contrast color pop.
  ;;
  ;; === General knowledge (applicable to any theme; derived from color
  ;; theory surveys including 色彩検定/PCCS, Itten/Judd, and de-facto UI
  ;; theme analysis) ===
  ;; - Hue circle and hue difference (PCCS 24-hue circle, ~15° per step;
  ;;   色彩検定 3級 level): hue diff 0 = identical hue (vary tone only);
  ;;   diff 1 = adjacent; 2-3 = similar (類似色相配色, harmonious, stable,
  ;;   analogous basic); 4-7 = medium; 8-10 = contrast (対照色相配色,
  ;;   warm/cool opposition, clear pop); 11-12 = complementary (補色, 180°,
  ;;   strong but use carefully).
  ;; - Geometric schemes (Itten/Judd "order principle"): diad 180°,
  ;;   triadic 120°, tetradic square 90° or rectangle. These are
  ;;   number-first (geometric positions for harmony) and can feel
  ;;   artificial/sensibility-light; treat as reference only, not primary
  ;;   for image-driven themes.
  ;; - Other harmony principles (Judd 4 principles, 色彩検定): similarity
  ;;   (common attributes harmonize), clarity/contrast (明瞭性), order
  ;;   (geometric as above), familiarity (なじみ, habitual/natural combos).
  ;;   Dominant-color scheme (one main hue family + tone variations);
  ;;   tone-on-tone etc.
  ;; - UI/theme practice (from nord, solarized, modus etc.): when bg is
  ;;   tinted (low-sat hue), analogous/cool-bias (cluster near bg hue)
  ;;   favors calm + mono-ramp prominence. Complementary/higher-pop for
  ;;   vibrancy. Strictly limit distinct hues (4-8 total). Base (bg/fg/
  ;;   most chrome) = mono ramp; accents limited to semantic roles.
  ;;   De-facto semantics (strong convergence): string/literal=green,
  ;;   keyword=purple/mauve, function=magenta or blue-magenta, type=cyan
  ;;   or blue (low pop structure), constant=near-bg blue, builtin=red,
  ;;   warning=yellow, error=red; success=green; link=blue. Transient/
  ;;   highlight can use more pop. Secondary/derived faces (many org,
  ;;   calendar, etc.) fall to mono + :inherit to avoid hue noise.
  ;;   Distribution tactics: even spacing (balance), clustered (warms for
  ;;   energy/alert/seasonal, cools for structure), sector emphasis.
  ;;   Reference choice: bg hue as anchor for analogous (common for
  ;;   tinted-bg calm themes); or key semantic / natural reference.
  ;;   Overall process (structural, any theme): 1. de-facto semantic survey,
  ;;   2. choose harmony type per desired image (calm vs pop vs seasonal),
  ;;   3. limit total hues, 4. use tone/s for variation instead of more
  ;;   hues, 5. visual tune. Hue-diff theory often for 2-4 colors; for 8+
  ;;   use composites (dominant analogous group + contrast accents).
  ;;
  ;; === Gensho-specific choice (image + theory mapping, clear which
  ;; pattern) ===
  ;; The "wet"/"dry" naming comes from imagining 玄昌石 in a rotenburo
  ;; (open-air hot spring), where the cool dark stone beautifully reflects
  ;; vivid small spring/autumn flower petals, momiji (autumn leaves),
  ;; orange outdoor light, and sky. Therefore we use a composite:
  ;; - PCCS "類似色相配色" (hue diff 2-3) + medium/contrast for the cool
  ;;   cluster around bg h=200 (sky/water/stone reflections, harmony +
  ;;   mono dominance). This is "dominant-color scheme" with cool main
  ;;   family (familiarity / なじみ from natural sky-on-stone).
  ;; - Limited warm "中差/対照色相配色" cluster (diff ~4-10 from green,
  ;;   higher from cool) for the "映り込む" seasonal vivid elements
  ;;   (petals, momiji, lamp glow) -- pop but not overwhelming.
  ;; - Large intentional gap green(~130) to cyan(~202): limits green
  ;;   variety ("green noise" prevention), reinforces cool dominance,
  ;;   controls effective hue diversity (aids frequency reduction on hue
  ;;   side). Not pure geometric (triadic 120° etc. avoided as
  ;;   number-prioritizing; see general note above).
  ;; - Reference/anchor: bg h~200 as cool anchor (PCCS similar-hue
  ;;   starting point; natural for sky reflection on stone). Warm cluster
  ;;   0-60° tuned to actual reflected seasonal/light hues.
  ;; - 8 hues total, respecting de-facto semantics (A above) as much as
  ;;   possible while fitting the reflection image.
  ;; Concretely this is "PCCS 類似色相配色 (cool dominant) + 中差/対照
  ;; (limited warm seasonal accents) + なじみ原理 (natural rotenburo
  ;; reflections) + de-facto semantic pattern", not a single 2-color
  ;; hue-diff or pure geometric.
  ;;
  ;; Current concrete: s=55 (微増 from 50, after additional freq reductions
  ;; for clutter/noise in minibuffer/org/dired while respecting de facto),
  ;; l slightly below mono7 fg (49 dry / 57 wet) to keep gray-ramp
  ;; dominance. Hues (see proposed refined below for naturalness):
  ;; red 0, orange 30, yellow 55, green 130, cyan 202 (bg anchor),
  ;; blue 242, purple 280, magenta 325.
  ;; Additional reductions (within de facto scope):
  ;; - minibuffer: orderless-match 4 faces now use cool cluster (cyan/blue/
  ;;   purple/magenta) instead of warm-pop (orange etc.) to reduce "ガチャガチャ";
  ;;   tooltip bg uses mono2 (neutral chrome plane per minimalist tooltip
  ;;   pattern -- Doom, Catppuccin -- not a colored cluster member).
  ;; - org: table/habit-overdue/agenda-current-time/document-title/date
  ;;   shifted to mono/low to reduce "うるさい" colored text (core todo/done
  ;;   status kept as de facto).
  ;; - dired: dired-perm-write at mono4 (low-key for permissions; intra-mono
  ;;   underline retired per the decoration policy below to align with the
  ;;   minimalist-themes survey on `:underline').
  ;; (Further s/l increase or frequency reduction possible after visual
  ;; confirmation; see below.)

  ;; Concretely, accents use s=55 (after minibuffer/org/dired freq reductions
  ;; for clutter) + l slightly below fg (49 dry / 57 wet) base. This (plus
  ;; heavy mono + :inherit) keeps the gray ramp dominant. The h assignments
  ;; and face definitions apply the survey patterns + specific rotenburo
  ;; reflection aesthetic. (s/l tweaks or frequency reduction possible later
  ;; -- see levers below.)

  ;; Face spec discipline (Emacs `face-spec-recalc' behavior)
  ;;
  ;; When `custom-theme-set-faces' overrides a face, the override does NOT
  ;; merge with the face's defface. `face-spec-recalc' first resets every
  ;; attribute to `unspecified', then applies the theme spec on top. The
  ;; defface spec is consulted only when no theme entry matches.
  ;;
  ;; The single exception is `:extend': if the theme spec leaves it
  ;; unspecified, `face-spec-recalc' copies the value from defface. So
  ;; `:extend' is the only attribute the theme can omit and still get the
  ;; defface value.
  ;;
  ;; (`set-face-attribute' is a different, lower-level primitive with true
  ;; merge semantics -- only the listed attributes change. The theme path
  ;; goes through `face-spec-recalc' and does NOT have those semantics.)
  ;;
  ;; Consequence for gensho: for any attribute other than `:extend' that
  ;; the defface specifies and we want to preserve, we must restate it
  ;; explicitly. Omitting it means dropping it. So:
  ;;   - `:extend'        -> omit (Emacs preserves the defface value).
  ;;   - everything else  -> state explicitly if we want it; omit only when
  ;;                         we actively want it cleared.

  ;; Decoration attribute policy (survey-derived; same structure as the
  ;; mono ramp / accent design notes above: facts -> pattern -> gensho
  ;; choice).
  ;;
  ;; Big-picture philosophy.  Modern minimalist themes (Nord, Modus,
  ;; Catppuccin) carry visual structure through a perceptual mono ramp
  ;; (~8 steps) and adjacent bg planes; borders are removed or flattened.
  ;; Information that the plane painting cannot carry (interactivity,
  ;; diagnostics, hierarchy, state) is delegated to color accents and --
  ;; only where the plane is insufficient -- to text-decoration
  ;; attributes.  Heavier themes (Zenburn, doom-themes) keep older
  ;; decoration conventions (released-button 3D box, broad straight-
  ;; underline usage, frequent inverse-video).  Gensho follows the
  ;; minimalist line on every attribute below.
  ;;
  ;; :underline t
  ;;   Survey: minimalist themes confine straight underline to (a)
  ;;   actionable navigation (`link', `link-visited').  Wave-style
  ;;   underline for diagnostics (flyspell/flycheck) is a separate
  ;;   built-in convention shared by all themes.  Heavier themes
  ;;   additionally underline dates, references, document-structure
  ;;   markers and "intra-mono distinction" cases such as dired
  ;;   permission chars; minimalist themes do NOT (Nord, Catppuccin,
  ;;   Modus do not override `dired-perm-write' / `marginalia-file-
  ;;   priv-*' to add underline).  Gensho choice: minimalist.  Allowed:
  ;;     (a) navigation: `link', `link-visited'.
  ;;     (b) defface-provided straight underline that other minimalist
  ;;         themes also let stand (they don't override): `calendar-
  ;;         today' (defface has `:underline t', conventional today
  ;;         marker -- we restate it to survive the theme replace).
  ;;     (c) wave-style diagnostics (override flyspell/flycheck etc.
  ;;         when needed -- keeps the built-in convention).
  ;;   NOT allowed (do not restate defface underline, do not invent
  ;;   intra-mono underline): document text and heading decoration --
  ;;   `org-date', `org-footnote', `org-ellipsis', `org-column-title',
  ;;   `org-latex-and-related', `eww-valid-certificate', font-lock
  ;;   tty-fallback underlines; and intra-mono distinction faces --
  ;;   `dired-perm-write', `marginalia-file-priv-write'.
  ;;
  ;; :weight bold
  ;;   Survey: all themes use bold for hierarchy/structural prominence
  ;;   (headings, outline levels) and state indicators (error/warning/
  ;;   success).  Minimalist themes (Modus) gate it behind a user
  ;;   toggle and default to "only where necessary"; heavier themes
  ;;   additionally bold every font-lock keyword/function-name/type.
  ;;   Gensho choice: minimalist.  Bold for exactly two roles:
  ;;     (1) Hierarchy / structural prominence -- headings where the
  ;;         bg plane alone cannot carry the body/heading split:
  ;;         `org-document-title', magit-section-heading family,
  ;;         `magit-diff-file-heading' family, `deft-*',
  ;;         `line-number-current-line', `tab-bar-tab-group-current',
  ;;         `tab-line-tab-modified'.
  ;;     (2) State indicators on low-cardinality markers:
  ;;         `error', `warning', `success', `mode-line-buffer-id'
  ;;         (the buffer identifier), `org-tag', `org-agenda-{current-
  ;;         time,date-today,date-weekend}', `org-dispatcher-highlight',
  ;;         `org-noter-*', `magit-process-{ok,ng}', `magit-tag',
  ;;         `magit-branch-{remote,local,current}', `magit-section-
  ;;         heading-selection', `magit-diff-file-heading-highlight',
  ;;         `ediff-fine-diff-*', `show-paren-match',
  ;;         `eww-valid-certificate'.
  ;;   No bold on syntax (font-lock-keyword-face etc.) -- color alone
  ;;   carries the semantic.  When defface has bold but gensho wants
  ;;   to drop it (high-frequency dense markers like `orderless-match-
  ;;   face-*'; chrome neutrals like `header-line', `eglot-mode-line'),
  ;;   simply omit `:weight' from the override -- theme replace makes
  ;;   it unspecified automatically.
  ;;
  ;; :box
  ;;   Survey: sparse in all themes (8-45 entries).  Heavier themes
  ;;   (Zenburn) use `:style released-button' on mode-line / headers
  ;;   (legacy 3D look); minimalist themes (Nord, Catppuccin) confine
  ;;   `:box' to clickable affordances with flat `:line-width N :color X'.
  ;;   Gensho choice: minimalist.  `:box' only where the bg plane
  ;;   alone cannot carry the affordance:
  ;;     - `magit-branch-current' (`:box t' delimits the current
  ;;       branch among a list of branches).
  ;;     - `magit-blame-heading' (sized box frames the blame line).
  ;;   Otherwise, gensho carries affordance via the bg plane (e.g.
  ;;   `help-key-binding' renders the key chip as a `mono2' fill on the
  ;;   `mono0' body plane -- the step is enough, no box is added).
  ;;   No `:style released-button' anywhere (fights slate flat).
  ;;
  ;; :slant italic
  ;;   Survey: all themes use italic for secondary/de-emphasized
  ;;   content (comments, docstrings, blockquotes, citations).
  ;;   Italic is gentler than bold and does not impede plane reading;
  ;;   even minimalist themes use it readily.  Gensho follows the
  ;;   common pattern.  Used on: `font-lock-comment-face',
  ;;   `marginalia-file-priv-link', `magit-branch-upstream',
  ;;   `org-agenda-clocking', `org-agenda-date-today' (with bold).
  ;;
  ;; :inverse-video
  ;;   Survey: minimalist themes (Nord 0, Catppuccin tty fallback only,
  ;;   Modus sparse) avoid it; heavier themes (Doom, Zenburn) use it
  ;;   sparsely.  Reason for avoiding: explicit bg/fg pairs are more
  ;;   predictable and interact more cleanly with the mono-ramp planes.
  ;;   Gensho choice: never use `:inverse-video'.  Where defface has
  ;;   it (`org-todo', `org-done', `org-date-selected'), gensho writes
  ;;   the equivalent display as an explicit `:foreground' / `:background'
  ;;   pair (theme replace drops the defface inverse-video for free).
  ;;
  ;; :inherit (not a decoration but related)
  ;;   When defface `:inherit' aligns with gensho intent, RESTATE it
  ;;   explicitly (theme override replaces defface, so omitted inherit
  ;;   is dropped).  When defface `:inherit' conflicts, re-target it
  ;;   (e.g. `dired-directory' -> `font-lock-type-face', `font-lock-
  ;;   doc-face' -> `mono4').
  ;;
  ;; Face-stack defence reset (`:weight normal :slant normal')
  ;;   Defface sometimes places an explicit normal-reset to prevent
  ;;   weight/slant inheriting from the face stack below (overlay
  ;;   before-string, text under another face's region).  Gensho
  ;;   preserves the reset only where the inheritance path exists:
  ;;   `magit-blame-heading' (before-string overlay; magit source
  ;;   comments on the inheritance risk), `org-column' (drawn atop
  ;;   underlying buffer text).  Margin overlays and independent
  ;;   regions do NOT need it -- `magit-log-author' / `magit-log-date'
  ;;   live in the margin overlay so the reset is omitted.
  ;;
  ;; No explicit `:foo unspecified'
  ;;   Theme override replaces defface entirely, so omitting an
  ;;   attribute IS unspecified.  Writing `:foo unspecified' carries
  ;;   no functional effect; the documentation value is covered by
  ;;   this block.  We therefore do not write any `:foo unspecified'
  ;;   in the spec list below.

  (custom-theme-set-faces
   'gensho

   ;; Optional integration: solaire-mode (unreal buffers) and
   ;; auto-dim-other-buffers-mode (non-selected windows).  These specs
   ;; bind gensho's dedicated `dim0' / `dim1' palette steps to the
   ;; mode-specific dim faces (dormant until the user enables the mode).
   ;; Enabling the modes is the user's choice; gensho only provides the
   ;; face wiring here.
   `(solaire-default-face ((,class (:background ,dim0))))
   `(solaire-hl-line-face ((,class (:background ,mono1))))
   `(solaire-region-face ((,class (:background ,mono1 :extend t))))
   `(auto-dim-other-buffers ((,class (:background ,dim0))))
   `(auto-dim-other-buffers-hide ((,class (:foreground ,dim0 :background ,dim0))))

   ;; --- Core primitives ---
   `(default ((,class (:foreground ,mono7 :background ,mono0))))
   `(cursor ((,class (:background ,mono6))))
   `(fringe ((,class (:background ,mono0))))
   `(border ((,class (:background ,mono0))))
   `(internal-border ((,class (:background ,mono0))))
   ;; Divider between windows. To achieve a clean slate feel (as preferred after
   ;; testing), we set the divider to the main content color (mono0). This
   ;; removes any visible seam line artifact between a differentiated side panel
   ;; (e.g. treemacs at mono1) and the main editor (mono0). The distinction
   ;; between areas is then expressed purely by the bg tone difference (where
   ;; used) + the content itself (tree structure vs code, icons, etc.) and
   ;; window geometry.
   ;;
   ;; This is a common de-facto approach for quiet, layered "stone" looks: avoid
   ;; a contrasting border line that fights the plane expression. Regular
   ;; content-to-content splits can still get subtle separation when
   ;; window-divider-mode is enabled (see the Gutter section below).
   ;;
   ;; Note on treemacs mono1: The step from main mono0 to mono1 is the standard
   ;; first auxiliary step (panels use this; the even weaker dim0/dim1 are for
   ;; the modes' non-selected content). If it feels too strong compared to the
   ;; main bg, you can override `treemacs-window-background-face` to mono0 in
   ;; your personal config; the panel character will come from its distinct
   ;; content, hl-line, and the clean divider treatment.
   `(vertical-border ((,class (:foreground ,mono0))))
   `(region ((,class (:background ,mono1))))
   `(secondary-selection ((,class (:background ,mono2))))
   `(highlight ((,class (:background ,mono1))))
   `(shadow ((,class (:foreground ,mono4))))
   `(match ((,class (:foreground ,mono0 :background ,green))))
   `(show-paren-match ((,class (:background ,mono1 :weight bold))))
   `(link ((,class (:foreground ,blue :underline t))))
   `(link-visited ((,class (:foreground ,purple :underline t))))
   `(error ((,class (:foreground ,red :weight bold))))
   `(warning ((,class (:foreground ,yellow :weight bold))))
   `(success ((,class (:foreground ,green :weight bold))))
   `(minibuffer-prompt ((,class (:foreground ,mono6))))
   `(minibuffer-nonselected ((,class (:foreground ,mono0 :background ,yellow))))
   `(tooltip ((,class (:foreground ,mono7 :background ,mono2 :inherit variable-pitch))))
   `(help-key-binding ((,class (:foreground ,mono7 :background ,mono2 :inherit fixed-pitch))))

   ;; --- Modeline, header-line, tab-bar, tab-line (UI chrome) ---
   ;; Per-face level assignments (the "Chrome direction" notes in the
   ;; mono ramp design above explain why sunken):
   ;; - tab-bar bg at mono2 (toolbar/frame chrome layer).
   ;; - Selected tab bg = mono0 (flushes with buffer default bg), so the
   ;;   active view surface is continuous from the tab "lid" down into
   ;;   the content -- the 玄昌石 slate recess.
   ;; - Inactive tabs sit on the bar (mono1) with dimmer fg for clear
   ;;   but quiet distinction.
   ;; - tab-line (per-window) follows the same logic but slightly more
   ;;   content-adjacent (bar at mono1 since it lives closer to buffer).
   ;; - mode-line uses mono0 (active = body level) and mono1 (inactive),
   ;;   matching tab-bar's sunken direction.  The active mode-line is
   ;;   visually flush with the editing surface (no bar separator);
   ;;   the inactive mode-line is the one that appears as a visible bar
   ;;   (mono1).
   `(mode-line ((,class (:foreground ,mono7 :background ,mono0))))
   ;; mode-line-inactive at mono1 -- the inactive chrome reference plane
   ;; shared with `tab-bar-tab-inactive' and `tab-line-tab-inactive', one
   ;; step above the deepest body stratum.  This level is invariant under
   ;; the walled / sunken / ha-ha choice for the active mode-line (see
   ;; "Chrome direction" notes in the mono ramp design above).
   `(mode-line-inactive ((,class (:foreground ,mono6 :background ,mono1))))
   `(mode-line-buffer-id ((,class (:weight bold))))
   ;; mode-line-highlight: minimalist convention (Nord, Doom) -- replace the
   ;; defface flat box on mouse-over with a plane shift (inherit `highlight'),
   ;; matching the "no boxes; bg-plane carries affordance" attribute policy.
   `(mode-line-highlight ((,class (:inherit highlight))))
   `(header-line ((,class (:foreground ,mono6 :background ,mono3))))
   `(tab-bar ((,class (:foreground ,mono7 :background ,mono2))))
   `(tab-bar-tab ((,class (:foreground ,mono7 :background ,mono0))))
   ;; tab inactive tabs sit "below" the bar (mono2) using mono1. This is a
   ;; chrome recess, not a content selection. Kept at mono1 for layer
   ;; coherence even with the compressed low end.
   `(tab-bar-tab-inactive ((,class (:foreground ,mono6 :background ,mono1))))
   `(tab-bar-tab-group-current ((,class (:inherit tab-bar-tab :weight bold))))
   `(tab-bar-tab-group-inactive ((,class (:inherit tab-bar-tab-inactive))))
   ;; tab-line lives closer to content. Its bar bg at mono1 and inactive at
   ;; mono1 are chrome-adjacent.
   `(tab-line ((,class (:foreground ,mono7 :background ,mono1))))
   `(tab-line-tab ((,class (:foreground ,mono6 :background ,mono1))))
   `(tab-line-tab-current ((,class (:foreground ,mono7 :background ,mono0))))
   `(tab-line-tab-inactive ((,class (:foreground ,mono5 :background ,mono1))))
   `(tab-line-tab-modified ((,class (:inherit tab-line-tab-current :weight bold))))

   ;; --- Gutter, dividers, borders (additional vertical/horizontal layering) ---
   ;; These provide extra "slab" and "grout" elements with almost zero added
   ;; decoration primitives, purely via mono ramp assignment.
   ;; Gutter (line numbers) acts as a vertical stone pillar on the left.
   ;;
   ;; Divider choice for clean slate feel (updated per testing):
   ;; Setting the divider to the main content color (mono0) produces the nicest
   ;; layered stone look without a visible seam line artifact. When using a
   ;; differentiated side panel (e.g. treemacs at mono1), the transition to the
   ;; main mono0 editor is seamless — the panel stands out through its tone
   ;; and content, not through an extra contrasting border.
   ;;
   ;; This is a common de-facto approach for quiet, modern slate/dark themes:
   ;; let the face (plane) tone difference and the content itself define areas,
   ;; rather than relying on a bright divider line that can fight the "面の
   ;; スレート" expression.
   ;;
   ;; For regular content-to-content splits, enabling `window-divider-mode`
   ;; can still give a very gentle separation using close tones in the ramp.
   ;; Enable with `(window-divider-mode 1)` + the width variables.
   ;;
   ;; Note on auxiliary panel contrast (treemacs etc.):
   ;; The step mono0 → mono1 is the standard first auxiliary step in the (main)
   ;; ramp. Dedicated dim levels (dim0/dim1) exist below it for the modes.
   ;; If the mono1 panel step feels too strong vs main mono0, override the
   ;; panel face to mono0 (content + hl-line + divider still define it --
   ;; common de-facto).
   ;;
   ;; Non-focused windows in general:
   ;; Normal buffers stay on the main mono0 plane. The primary de-facto way
   ;; to signal "this window is not the active one" is through
   ;; `mode-line-inactive` (set to mono1 here, which sits as a subtle
   ;; auxiliary-layer treatment at the chrome level without affecting editing
   ;; areas). A global subtle shift for every non-selected window is exactly
   ;; what `solaire-mode` and `auto-dim-other-buffers-mode` are designed for.
   ;; The theme provides face specs using dedicated dim0 (weaker than the
   ;; standard mono1 aux) for those modes. If you like the effect, using one
   ;; of those modes is the recommended route (our controlled mono ramp
   ;; works well with them).
   ;;
   ;; mode-line-inactive at mono1 already provides a gentle auxiliary feel
   ;; that is consistent with how we treat explicit panels.
   ;;
   ;; child-frame-border keeps popups framed consistently with other chrome.
   `(line-number ((,class (:foreground ,mono4 :background ,mono0))))
   `(line-number-current-line ((,class (:foreground ,mono6 :background ,mono1 :weight bold))))
   `(line-number-major-tick ((,class (:foreground ,mono3 :background ,mono0 :weight bold))))
   `(line-number-minor-tick ((,class (:foreground ,mono4 :background ,mono0))))
   `(window-divider ((,class (:foreground ,mono0))))
   `(window-divider-first-pixel ((,class (:foreground ,mono1))))
   `(window-divider-last-pixel ((,class (:foreground ,mono0))))
   `(child-frame-border ((,class (:background ,mono2))))

   ;; --- Font-lock (syntax primitives; bases for inherits) ---
   `(font-lock-comment-face ((,class (:foreground ,mono5 :slant italic))))
   `(font-lock-string-face ((,class (:foreground ,green))))
   `(font-lock-doc-face ((,class (:foreground ,mono4))))
   `(font-lock-keyword-face ((,class (:foreground ,purple))))
   `(font-lock-builtin-face ((,class (:foreground ,red))))
   `(font-lock-variable-name-face ((,class (:foreground ,mono6))))
   `(font-lock-function-name-face ((,class (:foreground ,magenta))))
   `(font-lock-type-face ((,class (:foreground ,cyan))))
   `(font-lock-constant-face ((,class (:foreground ,blue))))
   `(font-lock-warning-face ((,class (:foreground ,yellow))))

   ;; --- Search, jump, isearch (interactive highlights) ---
   `(isearch ((,class (:foreground ,mono0 :background ,orange))))
   `(lazy-highlight ((,class (:foreground ,mono0 :background ,mono2))))
   `(avy-lead-face ((,class (:foreground ,mono0 :background ,blue))))
   `(avy-lead-face-0 ((,class (:foreground ,mono0 :background ,orange))))
   `(avy-lead-face-1 ((,class (:foreground ,mono0 :background ,red))))
   `(avy-lead-face-2 ((,class (:foreground ,mono0 :background ,magenta))))

   ;; --- Completion & narrowing (modern UIs) ---
   `(vertico-current ((,class (:background ,mono1))))
   `(orderless-match-face-0 ((,class (:foreground ,cyan))))
   `(orderless-match-face-1 ((,class (:foreground ,blue))))
   `(orderless-match-face-2 ((,class (:foreground ,purple))))
   `(orderless-match-face-3 ((,class (:foreground ,magenta))))
   `(consult-buffer ((,class (:foreground ,mono6))))
   `(consult-file ((,class (:foreground ,mono5))))
   `(corfu-default ((,class (:background ,mono1))))
   `(corfu-current ((,class (:foreground ,mono7 :background ,mono2))))
   `(corfu-bar ((,class (:background ,mono5))))
   `(corfu-border ((,class (:background ,mono2))))

   ;; --- Navigation & project (dired, bookmark, etc.) ---
   `(dired-directory ((,class (:inherit font-lock-type-face))))
   `(dired-perm-write ((,class (:foreground ,mono4))))
   `(bookmark-face ((,class (:foreground ,mono5 :distant-foreground ,mono5))))
   `(deadgrep-filename-face ((,class (:inherit font-lock-builtin-face))))
   `(treemacs-root-face ((,class (:inherit font-lock-constant-face))))
   ;; Slate sidebar: give the whole treemacs window a distinct layer (mono1)
   ;; so it reads as a side stone panel next to the main content plane (mono0).
   ;; With `vertical-border` at mono0, the transition is clean (no extra seam
   ;; line). The panel stands out through its tone + distinct content.
   ;; If the mono1 step feels strong vs main mono0, you can override this face
   ;; to mono0 in your config; distinction will come from content, hl-line,
   ;; and the clean divider.
   ;; hl-line inside the panel uses the next step (mono2) for subtle selection.
   `(treemacs-window-background-face ((,class (:background ,mono1))))
   `(treemacs-hl-line-face ((,class (:background ,mono2))))
   `(treemacs-directory-face ((,class (:inherit font-lock-type-face))))
   `(treemacs-directory-collapsed-face ((,class (:inherit treemacs-directory-face))))
   `(treemacs-file-face ((,class (:foreground ,mono6))))
   `(treemacs-git-added-face ((,class (:foreground ,green))))
   `(treemacs-git-modified-face ((,class (:foreground ,yellow))))
   `(treemacs-git-untracked-face ((,class (:foreground ,cyan))))
   `(treemacs-git-ignored-face ((,class (:inherit shadow))))
   `(treemacs-git-conflict-face ((,class (:foreground ,red))))

   ;; dirvish (dired-based modern file manager). We style its custom hl/inactive
   ;; faces to follow the mono ramp. For dirvish-side (sidebar usage) the main
   ;; directory listing background remains the normal content plane (mono0 /
   ;; `default') because dirvish re-uses dired buffers and does not expose a
   ;; dedicated window-background-face like treemacs. Distinction for the pane
   ;; comes from header-line (mono3), our hl-line faces, window dividers (which
   ;; blend to panel tone when next to a mono1 area), and optional multi-pane
   ;; layout. This matches the design constraints of the package. See README
   ;; for a user hook example if you want mono1 for the whole side pane.
   ;; Recommended dired-native alternative to treemacs (for users who prefer
   ;; dired-native navigation with built-in preview).
   `(dirvish-hl-line ((,class (:background ,mono2 :extend t))))
   `(dirvish-hl-line-inactive ((,class (:background ,mono1 :extend t))))
   `(dirvish-inactive ((,class (:inherit shadow))))

   ;; --- Marginalia (completion annotations; tone down lively file attrs) ---
   ;; Follows the mono usage (supplementary file info -> shadow/mono4 or
   ;; font-lock-comment-face/mono5) and colored semantic de-facto documented
   ;; in the design notes above.  Explicitly overrides marginalia's default
   ;; inherits from font-lock-* (which would produce purple/red/magenta/cyan
   ;; noise on "lrwxr-xr-x ..." permission strings and similar).
   ;; All marginalia-file-priv-* now use the shadow family for visual
   ;; uniformity within the compact permission annotation string.
   ;; Weight/italic provide intra-mono distinction (e.g. bold 'd' for dir,
   ;; italic for link).  Underline is intentionally NOT used here -- see
   ;; the `:underline' decoration policy above (minimalist themes such as
   ;; Nord, Catppuccin and Modus do not underline intra-mono distinction
   ;; cases like `dired-perm-write' / `marginalia-file-priv-*'; gensho
   ;; follows that line).  Leverages :inherit heavily
   ;; to respect marginalia's own face hierarchy (e.g. marginalia-size
   ;; inherits number, marginalia-file-name inherits documentation)
   ;; without touching the base font-lock-*/shadow definitions.
   `(marginalia-documentation ((,class (:inherit font-lock-comment-face))))
   `(marginalia-file-name ((,class (:inherit marginalia-documentation))))
   `(marginalia-file-owner ((,class (:inherit shadow))))
   `(marginalia-size ((,class (:inherit shadow))))
   `(marginalia-date ((,class (:inherit shadow))))
   `(marginalia-file-priv-no ((,class (:inherit shadow))))
   `(marginalia-file-priv-dir ((,class (:inherit shadow :weight bold))))
   `(marginalia-file-priv-link ((,class (:inherit shadow :slant italic))))
   `(marginalia-file-priv-read ((,class (:inherit shadow))))
   `(marginalia-file-priv-write ((,class (:inherit shadow))))
   `(marginalia-file-priv-exec ((,class (:inherit shadow))))
   `(marginalia-file-priv-other ((,class (:inherit shadow))))
   `(marginalia-file-priv-rare ((,class (:inherit shadow))))
   ;; Other marginalia faces (key, number, on/off, archive, installed,
   ;; value, etc.) intentionally left to their defface defaults or the
   ;; existing font-lock-/success-/error- inherits; they align with
   ;; semantic de-facto (e.g. on=success/green, archive=warning) or the
   ;; cool cluster used for orderless matches and do not contribute to
   ;; the file-perm liveliness problem.

   ;; --- Dev tools (eglot, compilation, ein) ---
   `(eglot-mode-line ((,class (:inherit mode-line))))
   `(compilation-info ((,class (:inherit success))))
   `(compilation-mode-line-fail ((,class (:inherit compilation-error))))
   `(compilation-mode-line-exit ((,class (:inherit compilation-info))))

   ;; --- Evil / vim-emulation ---
   `(evil-snipe-first-match-face ((,class (:background ,mono3))))

   ;; --- Outlines (inherit font-lock-*) ---
   `(outline-1 ((,class (:inherit font-lock-type-face))))
   `(outline-2 ((,class (:inherit font-lock-variable-name-face))))
   `(outline-3 ((,class (:inherit font-lock-constant-face))))
   `(outline-4 ((,class (:inherit font-lock-builtin-face))))
   `(outline-5 ((,class (:inherit font-lock-function-name-face))))
   `(outline-6 ((,class (:inherit font-lock-string-face))))
   `(outline-7 ((,class (:inherit font-lock-warning-face))))
   `(outline-8 ((,class (:inherit font-lock-keyword-face))))

   ;; --- Org mode + extensions (rich derived faces) ---
   ;; Document
   `(org-document-title ((,class (:foreground ,mono7 :weight bold))))
   `(org-document-info ((,class (:foreground ,mono6))))

   ;; TODO / DONE
   `(org-todo ((,class (:foreground ,mono0 :background ,red))))
   `(org-done ((,class (:foreground ,mono0 :background ,green))))
   `(org-headline-todo ((,class (:foreground ,mono7))))
   `(org-headline-done ((,class (:inherit font-lock-comment-face))))
   `(org-archived ((,class (:inherit org-headline-done))))
   `(org-agenda-done ((,class (:inherit org-headline-done))))
   `(org-agenda-dimmed-todo-face ((,class (:inherit font-lock-comment-face))))

   ;; Markup / structure
   `(org-drawer ((,class (:inherit font-lock-comment-face))))
   `(org-special-keyword ((,class (:inherit font-lock-comment-face))))
   `(org-ellipsis ((,class (:foreground ,mono4))))

   ;; Tables / columns
   `(org-table ((,class (:foreground ,mono6))))
   `(org-table-header ((,class (:foreground ,mono7 :background ,mono2))))
   `(org-column ((,class (:foreground ,mono7 :background ,mono2 :weight normal :slant normal :strike-through nil :underline nil))))
   `(org-column-title ((,class (:foreground ,mono7 :background ,mono2))))
   `(org-tag ((,class (:weight bold))))

   ;; Timestamps / dates
   `(org-time-stamp ((,class (:foreground ,mono5))))
   `(org-date ((,class (:foreground ,mono5))))
   `(org-sexp-date ((,class (:foreground ,mono5))))
   `(org-date-selected ((,class (:foreground ,mono0 :background ,orange))))

   ;; Formula / footnote
   `(org-formula ((,class (:foreground ,yellow))))
   `(org-footnote ((,class (:foreground ,mono5))))

   ;; Agenda - structure & dates
   `(org-agenda-structure ((,class (:foreground ,mono6))))
   ;; The same green org-foresight rules its bars at, and no weight.  The
   ;; package draws this very line itself whenever the hour is pinned -- in
   ;; `org-foresight-report-now', set below -- so a different colour here
   ;; means the same moment looks like two different things depending on
   ;; which of them drew it.
   `(org-agenda-current-time ((,class (:foreground ,green))))
   `(org-agenda-date-today ((,class (:foreground ,mono6 :weight bold :slant italic))))
   `(org-agenda-date-weekend ((,class (:foreground ,mono4 :weight bold))))
   `(org-agenda-clocking ((,class (:slant italic :inherit secondary-selection))))
   `(org-time-grid ((,class (:inherit font-lock-comment-face))))

   ;; Scheduling
   `(org-scheduled ((,class (:foreground ,mono6))))
   `(org-scheduled-today ((,class (:foreground ,mono6))))
   `(org-scheduled-previously ((,class (:foreground ,mono5))))
   `(org-upcoming-deadline ((,class (:inherit org-scheduled-previously))))

   ;; Habits
   `(org-habit-clear-face ((,class (:foreground ,mono0 :background ,blue))))
   `(org-habit-clear-future-face ((,class (:foreground ,blue :background ,mono2))))
   `(org-habit-ready-face ((,class (:foreground ,mono0 :background ,green))))
   `(org-habit-ready-future-face ((,class (:foreground ,green :background ,mono2))))
   `(org-habit-alert-face ((,class (:foreground ,mono0 :background ,yellow))))
   `(org-habit-alert-future-face ((,class (:foreground ,yellow :background ,mono2))))
   `(org-habit-overdue-face ((,class (:foreground ,mono0 :background ,red))))
   `(org-habit-overdue-future-face ((,class (:foreground ,orange :background ,mono3))))

   ;; Other org (low-frequency)
   `(org-clock-overlay ((,class (:foreground ,mono7 :background ,mono2))))
   `(org-mode-line-clock-overrun ((,class (:foreground ,mono0 :background ,red))))
   `(org-dispatcher-highlight ((,class (:foreground ,mono7 :background ,mono2 :weight bold))))
   `(org-latex-and-related ((,class (:foreground ,mono5))))
   `(org-agenda-restriction-lock ((,class (:foreground ,mono7 :background ,mono2))))

   ;; Extensions (org-around packages)
   `(org-roam-header-line ((,class (:inherit header-line))))
   `(org-noter-notes-exist-face ((,class (:foreground ,mono6 :weight bold))))
   `(org-noter-no-notes-exist-face ((,class (:foreground ,mono5 :weight bold))))
   `(deft-header-face ((,class (:inherit font-lock-builtin-face :weight bold))))
   `(deft-title-face ((,class (:inherit font-lock-constant-face :weight bold))))

   ;; org-dayflow — timeline column chrome on the mono/dim ramp (not raw gray20).
   ;; Weekend bands must stay one step above mono0 so they read as texture, not
   ;; as a second UI layer; dim0 sits between mono0 and mono1 for that purpose.
   `(org-dayflow-weekend-column-face ((,class (:background ,dim0 :extend t))))
   `(org-dayflow-weekend-face ((,class (:foreground ,mono4 :weight bold))))
   `(org-dayflow-weekday-face ((,class (:foreground ,mono5))))
   `(org-dayflow-units-face ((,class (:foreground ,mono5))))
   `(org-dayflow-label-face ((,class (:foreground ,mono5))))
   `(org-dayflow-query-face ((,class (:inherit org-agenda-structure))))
   `(org-dayflow-now-column-face ((,class (:background ,mono1 :extend t))))
   `(org-dayflow-cursor-column-face ((,class (:background ,mono1 :extend t))))
   `(org-dayflow-now-unit-face ((,class (:inherit calendar-today))))
   `(org-dayflow-cursor-unit-face ((,class (:inherit org-date-selected))))
   `(org-dayflow-title-done-face ((,class (:inherit org-headline-done :strike-through t))))

   ;; org-foresight — the capacity bar and the rows it adds to the agenda.
   ;; Two rules.  Grey says "work already claimed", and only three steps of it,
   ;; two apart, because a ramp fine enough to encode six things is a ramp
   ;; nobody reads; booked tops out at mono6, the badge's own grey, so nothing
   ;; inside a section is louder than the badge announcing it.  Colour is kept
   ;; for what is not claimed work, which is where the decisions are: blue is
   ;; room -- spare, and the free gaps it is made of -- and green is life,
   ;; neither work nor room, and not to be mistaken for either.  The bar draws
   ;; private between travel and promised, so every pair that touches is either
   ;; two steps of grey apart or a change of hue.
   `(org-foresight-report-booked ((,class (:foreground ,mono6))))
   `(org-foresight-report-travel ((,class (:foreground ,mono4))))
   `(org-foresight-report-promised ((,class (:foreground ,mono2))))
   `(org-foresight-report-spare ((,class (:foreground ,blue))))
   ;; Emptiness, wherever it is drawn: the same dot in the bar and in the
   ;; sparkline, so two identical characters stop looking like two sizes.
   `(org-foresight-report-empty ((,class (:foreground ,mono4 :weight bold))))
   `(org-foresight-report-private ((,class (:foreground ,green))))
   ;; The reserve keeps the package's outline in the overrun's own yellow: it
   ;; is the last thing between the day and an overrun, so spending it is
   ;; being over without having said so.  `unclocked' is that same reserve
   ;; found spent, so it is the same yellow -- the outline held open ahead of
   ;; now, met empty behind it.  The bar boxes every segment itself, so
   ;; nothing here needs to set one.
   `(org-foresight-report-overcommitted ((,class (:foreground ,yellow))))
   `(org-foresight-report-surge ((,class (:foreground ,yellow))))
   `(org-foresight-report-unclocked ((,class (:foreground ,yellow))))
   ;; Hours the watcher accounted for and nobody claimed: the grey the
   ;; sparkline already gives time away from the machine.
   `(org-foresight-report-away ((,class (:foreground ,mono4))))
   ;; Where now falls, in the colour of the hours it protects: everything
   ;; right of the mark is the part of the day still to be decided.
   `(org-foresight-report-now ((,class (:foreground ,green))))
   `(org-foresight-agenda-derived ((,class (:slant italic))))
   `(org-foresight-agenda-free ((,class (:foreground ,blue :slant italic))))
   ;; The one mark that reports no decision, so the one mark with no hue: the
   ;; other two borrow the overrun's yellow and the colour of room precisely
   ;; because something has to be done about them.  mono6, the badges' grey --
   ;; a step brighter than the rows it sits among, which is all a mark that
   ;; means "nothing to resolve here" needs to be.
   `(org-foresight-agenda-shared ((,class (:foreground ,mono6))))
   ;; Where a row came from, not what to do about it: the same quiet grey as
   ;; the shared mark, and the shape tells them apart.
   `(org-foresight-agenda-arrival ((,class (:foreground ,mono6))))
   ;; The bracket down the left edge marking the working hours.  A step below
   ;; the marks: a mark asks for a decision and the frame asks for nothing, so
   ;; it should be findable when looked for and invisible when not.
   `(org-foresight-agenda-spine ((,class (:foreground ,mono5))))

   ;; --- Magit (Git porcelain; rich derived mode) ---
   ;; Follows design notes: "Org/Magit/Agenda and similar rich modes inherit the
   ;; font-lock and mono decisions heavily; hues only for key status indicators".
   ;; All specs use the variant-specific mono*/accent vars bound in the enclosing
   ;; let*, so no explicit dark/light branching is needed here (unlike many
   ;; magit deffaces).  This also fixes "floating" highlights/headers in gensho's
   ;; non-standard "light" variant (dry: still dark bg + light text, unlike
   ;; typical white-bg light themes).
   ;; Prefer :inherit + mono* over direct colors for harmony and DRY.
   ;; `:extend t' on diff/heading/blame bgs is supplied by defface and
   ;; preserved by `face-spec-recalc' (see face-spec discipline notes above),
   ;; so it is not restated here.
   `(magit-section-highlight ((,class (:background ,mono1))))
   `(magit-section-heading ((,class (:inherit font-lock-keyword-face :weight bold))))
   `(magit-section-secondary-heading ((,class (:weight bold))))
   `(magit-section-heading-selection ((,class (:inherit magit-section-highlight :foreground ,orange :weight bold))))
   `(magit-diff-file-heading ((,class (:weight bold))))
   `(magit-diff-file-heading-highlight ((,class (:inherit magit-section-highlight :weight bold))))
   `(magit-diff-file-heading-selection ((,class (:inherit magit-diff-file-heading-highlight :foreground ,orange))))
   `(magit-diff-hunk-heading ((,class (:background ,mono2 :foreground ,mono6))))
   `(magit-diff-hunk-heading-highlight ((,class (:background ,mono3 :foreground ,mono7))))
   `(magit-diff-hunk-heading-selection ((,class (:inherit magit-diff-hunk-heading-highlight :foreground ,orange))))
   `(magit-diff-conflict-heading ((,class (:inherit magit-diff-hunk-heading))))
   `(magit-diff-revision-summary ((,class (:inherit magit-diff-hunk-heading))))
   `(magit-diff-lines-heading ((,class (:background ,orange :foreground ,mono0))))
   `(magit-diff-context ((,class (:foreground ,mono5))))
   ;; Bumped the non-highlight diff backgrounds from mono1 to mono2 (and their
   ;; highlight counterparts from mono2 to mono3) for the same reason as other
   ;; subtle content bgs: visibility on mono1-dimmed windows and de-facto
   ;; "this region is different" contrast on normal mono0 content.
   `(magit-diff-context-highlight ((,class (:background ,mono1 :foreground ,mono6))))
   `(magit-diff-added ((,class (:background ,mono1 :foreground ,green))))
   `(magit-diff-added-highlight ((,class (:background ,mono2 :foreground ,green))))
   `(magit-diff-removed ((,class (:background ,mono1 :foreground ,red))))
   `(magit-diff-removed-highlight ((,class (:background ,mono2 :foreground ,red))))
   `(magit-diff-base ((,class (:background ,mono1 :foreground ,yellow))))
   `(magit-diff-base-highlight ((,class (:background ,mono2 :foreground ,yellow))))
   `(magit-diff-our ((,class (:inherit magit-diff-removed))))
   `(magit-diff-their ((,class (:inherit magit-diff-added))))
   `(magit-diff-our-highlight ((,class (:inherit magit-diff-removed-highlight))))
   `(magit-diff-their-highlight ((,class (:inherit magit-diff-added-highlight))))
   `(magit-diffstat-added ((,class (:foreground ,green))))
   `(magit-diffstat-removed ((,class (:foreground ,red))))
   `(magit-process-ok ((,class (:foreground ,green :weight bold))))
   `(magit-process-ng ((,class (:foreground ,red :weight bold))))
   `(magit-log-author ((,class (:foreground ,mono6))))
   `(magit-log-date ((,class (:foreground ,mono5))))
   `(magit-log-graph ((,class (:foreground ,mono4))))
   `(magit-dimmed ((,class (:foreground ,mono4))))
   `(magit-hash ((,class (:foreground ,mono4))))
   `(magit-tag ((,class (:foreground ,yellow :weight bold))))
   `(magit-branch-remote ((,class (:foreground ,green :weight bold))))
   `(magit-branch-local ((,class (:foreground ,cyan :weight bold))))
   `(magit-branch-current ((,class (:foreground ,blue :weight bold :box t))))
   `(magit-branch-upstream ((,class (:slant italic))))
   `(magit-head ((,class (:inherit magit-branch-local))))
   `(magit-refname ((,class (:foreground ,mono5))))
   `(magit-keyword ((,class (:inherit font-lock-string-face))))
   `(magit-keyword-squash ((,class (:inherit font-lock-warning-face))))
   `(magit-blame-highlight ((,class (:background ,mono2))))
   `(magit-blame-heading ((,class (:background ,mono2 :foreground ,mono6
                                               :weight normal :slant normal
                                               :box (:color ,mono2 :line-width 2)))))
   `(magit-blame-summary ((,class (:foreground ,mono7))))
   `(magit-blame-hash ((,class (:foreground ,mono4))))
   `(magit-blame-name ((,class (:foreground ,mono6))))
   `(magit-blame-date ((,class (:foreground ,mono5))))

   ;; --- transient ---
   ;; Override only the faces that hard-code hex/ANSI names in their defface.
   ;; The rest of transient's faces inherit cleanly (font-lock, shadow,
   ;; highlight, font-lock-builtin-face) and need no entry here.
   ;; Key colors follow gensho semantics: stay=green (continuity),
   ;; return=yellow (warn/route), recurse=blue (descend/link),
   ;; stack=magenta (escalate), exit=orange (decisive leave), noop=mono4
   ;; (shadow ramp). Box colors of the (non)standard-key faces are pinned
   ;; to gensho's cyan / magenta instead of vanilla ANSI cyan / magenta.
   `(transient-enabled-suffix  ((,class (:background ,green :foreground ,mono0 :weight bold))))
   `(transient-disabled-suffix ((,class (:background ,red   :foreground ,mono0 :weight bold))))
   `(transient-key-stay        ((,class (:foreground ,green))))
   `(transient-key-noop        ((,class (:foreground ,mono4))))
   `(transient-key-return      ((,class (:foreground ,yellow))))
   `(transient-key-recurse     ((,class (:foreground ,blue))))
   `(transient-key-stack       ((,class (:foreground ,magenta))))
   `(transient-key-exit        ((,class (:foreground ,orange))))
   `(transient-nonstandard-key ((,class (:box (:line-width (-1 . -1) :color ,cyan)))))
   `(transient-mismatched-key  ((,class (:box (:line-width (-1 . -1) :color ,magenta)))))

   ;; --- diff-hl / ediff ---
   ;; Mirrors the `magit-diff-*' semantic mapping (red=removed, green=added,
   ;; yellow=base/combined, blue=ancestor). Follows the face-spec discipline
   ;; documented above: `:extend t' is omitted when the defface already
   ;; supplies it (vanilla ediff-current-*/ediff-even-*/ediff-odd-* defaces
   ;; all carry it). `ediff-fine-*' defaces have no `:extend t' at 88+ colors
   ;; and no `:weight bold' either, so `:weight bold' is added explicitly as
   ;; our chosen emphasis marker for fine-diff sub-regions inside a current
   ;; diff. diff-hl renders one column in the fringe, so only foreground hue
   ;; matters; bg/extend from the inherit chain are intentionally dropped.

   ;; diff-hl
   `(diff-hl-insert ((,class (:foreground ,green))))
   `(diff-hl-delete ((,class (:foreground ,red))))
   `(diff-hl-change ((,class (:foreground ,yellow))))

   ;; ediff: current diff (focused chunk)
   `(ediff-current-diff-A        ((,class (:background ,mono1 :foreground ,red))))
   `(ediff-current-diff-B        ((,class (:background ,mono1 :foreground ,green))))
   `(ediff-current-diff-C        ((,class (:background ,mono1 :foreground ,yellow))))
   `(ediff-current-diff-Ancestor ((,class (:background ,mono1 :foreground ,blue))))

   ;; ediff: fine diff (sub-region emphasis within current; bold is our marker)
   `(ediff-fine-diff-A           ((,class (:background ,mono2 :foreground ,red    :weight bold))))
   `(ediff-fine-diff-B           ((,class (:background ,mono2 :foreground ,green  :weight bold))))
   `(ediff-fine-diff-C           ((,class (:background ,mono2 :foreground ,yellow :weight bold))))
   `(ediff-fine-diff-Ancestor    ((,class (:background ,mono2 :foreground ,blue   :weight bold))))

   ;; ediff: non-current diffs (alternating markers; quiet so current wins)
   `(ediff-even-diff-A           ((,class (:background ,mono1 :foreground ,mono5))))
   `(ediff-even-diff-B           ((,class (:background ,mono1 :foreground ,mono5))))
   `(ediff-even-diff-C           ((,class (:background ,mono1 :foreground ,mono5))))
   `(ediff-even-diff-Ancestor    ((,class (:background ,mono1 :foreground ,mono5))))
   `(ediff-odd-diff-A            ((,class (:background ,mono1 :foreground ,mono5))))
   `(ediff-odd-diff-B            ((,class (:background ,mono1 :foreground ,mono5))))
   `(ediff-odd-diff-C            ((,class (:background ,mono1 :foreground ,mono5))))
   `(ediff-odd-diff-Ancestor     ((,class (:background ,mono1 :foreground ,mono5))))

   ;; --- Calendar / eww (other apps) ---
   `(calendar-today ((,class (:inherit font-lock-warning-face :underline t))))
   `(calendar-weekend-header ((,class (:inherit font-lock-type-face))))
   `(holiday ((,class (:background ,mono2))))
   `(diary ((,class (:inherit font-lock-string-face))))
   `(eww-valid-certificate ((,class (:weight bold :foreground ,mono6))))

   ;; --- org-timeblock (calendar day/week time blocks) ---
   ;; Block palette maps to gensho's muted hues with mono0 knockout text (as in
   ;; `match'); the hour line and selection/mark use the mono ramp so they never
   ;; collide with a block hue.  now = green (present position); red is reserved
   ;; for caution/warning and is therefore not used for the now line.
   `(org-timeblock-red     ((,class (:background ,red     :foreground ,mono0 :extend t))))
   `(org-timeblock-green   ((,class (:background ,green   :foreground ,mono0 :extend t))))
   `(org-timeblock-yellow  ((,class (:background ,yellow  :foreground ,mono0 :extend t))))
   `(org-timeblock-blue    ((,class (:background ,blue    :foreground ,mono0 :extend t))))
   `(org-timeblock-magenta ((,class (:background ,magenta :foreground ,mono0 :extend t))))
   `(org-timeblock-cyan    ((,class (:background ,cyan    :foreground ,mono0 :extend t))))
   `(org-timeblock-hours-line ((,class (:background ,mono2 :extend t))))
   `(org-timeblock-current-time-indicator ((,class (:background ,green))))
   `(org-timeblock-select ((,class (:background ,mono5 :foreground ,mono0 :extend t))))
   `(org-timeblock-mark ((,class (:background ,mono3 :foreground ,mono7 :extend t))))))

;; ANSI 16-color slot strategy (Solarized convention).
;;
;; 8 hues fill: red/green/yellow/blue/magenta/cyan (slots 1-6) plus
;; orange at brightred (9) and purple at brightmagenta (13). The
;; remaining 8 slots carry the mono ramp:
;;
;;   slot 0  black        mono1   (subtle, just above bg)
;;   slot 7  white        mono5   (medium fg)
;;   slot 8  brightblack  mono0   (= bg; intentionally near-invisible for dim
;;                                   text, following Solarized's base03 placement)
;;   slot 10 brightgreen  mono2
;;   slot 11 brightyellow mono3
;;   slot 12 brightblue   mono4
;;   slot 14 brightcyan   mono6   (a usable light grey, NEVER bg — Solarized's
;;                                   base1 / Nord's nord7 placement)
;;   slot 15 brightwhite  mono7   (brightest fg)
;;
;; Only slot 8 (brightblack) collides with bg by design; this is the long-
;; standing Solarized convention used by every dim-comment-aware tool.
;; Every other slot is a distinct readable color, so TUI tools that write
;; brightcyan, brightyellow, etc. produce visible output.
(defconst gensho--export-name-map
  '((mono0   . background)
    (mono0   . brightblack)    ; was: brightcyan (slot 14) — moved per Solarized
    (mono1   . black)
    (mono2   . brightgreen)    ; was: brightblack (slot 8)
    (mono3   . brightyellow)   ; was: brightblue (slot 12); slot 11 used to be mono6
    (mono4   . brightblue)     ; was: brightgreen (slot 10)
    (mono5   . white)
    (mono6   . brightcyan)     ; was: brightyellow (slot 11) — fixes slot 14 collision
    (mono7   . foreground)
    (mono7   . brightwhite)
    (red     . red)
    (orange  . brightred)
    (yellow  . yellow)
    (green   . green)
    (cyan    . cyan)
    (blue    . blue)
    (purple  . brightmagenta)
    (magenta . magenta)))

;;;###autoload
(defun gensho-export-palette (format &optional variant)
  "Export the palette for external tools.
FORMAT is `json', `alist', or `hex-list'.
VARIANT is `wet' or `dry' (defaults from `frame-background-mode')."
  (let* ((palette (gensho-palette variant))
         ;; Canonical ANSI 0-15 slot order. Earlier versions of this list had
         ;; brightyellow and brightmagenta swapped, which would mislabel
         ;; positions 11 and 13 for any external consumer that indexes by
         ;; slot number rather than by name.
         (ordered-keys '(black red green yellow blue magenta cyan white
                               brightblack brightred brightgreen brightyellow
                               brightblue brightmagenta brightcyan brightwhite)))
    (pcase format
      ('alist
       (mapcar (lambda (pair)
                 (let* ((internal (car pair))
                        (ansi (cdr pair)))
                   (cons ansi (alist-get internal palette))))
               gensho--export-name-map))
      ('hex-list
       (mapcar (lambda (ansi)
                 (let ((internal (car (rassoc ansi gensho--export-name-map))))
                   (alist-get internal palette)))
               ordered-keys))
      ('json
       (let ((json-pairs
              (mapconcat
               (lambda (pair)
                 (let* ((internal (car pair))
                        (ansi (cdr pair))
                        (v (alist-get internal palette)))
                   (format "  %S: %S" (symbol-name ansi) v)))
               gensho--export-name-map
               ",\n")))
         (concat "{\n" json-pairs "\n}")))
      (_
       (error "Unsupported FORMAT: %s. Use 'json, 'alist or 'hex-list" format)))))

;;;###autoload
(defun gensho-apply-hsl-correction (&optional correction)
  "Recompute derived palettes using CORRECTION (or current value) and refresh.

If the gensho theme is active this disables and reloads it so the new
palette takes effect immediately (preserving the prior
`frame-background-mode').  This is the supported way to change the
correction at runtime after the package has been loaded.

Example:
  (setq gensho-hsl-correction \\='(0.0 0.0 -2.0))
  (gensho-apply-hsl-correction)"
  (when correction
    (setq gensho-hsl-correction correction))
  (gensho--recompute-derived-palettes)
  (when (custom-theme-enabled-p 'gensho)
    (let ((was-light (eq frame-background-mode 'light)))
      (disable-theme 'gensho)
      (setq frame-background-mode (if was-light 'light 'dark))
      (load-theme 'gensho t))))

;;;###autoload
(when load-file-name
  (add-to-list 'custom-theme-load-path
               (file-name-directory load-file-name)))

(provide-theme 'gensho)
(provide 'gensho-theme)
;;; gensho-theme.el ends here

