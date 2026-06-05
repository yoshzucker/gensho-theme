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
;; dired-perm-write to mono4+underline) keep core semantics intact.
(defconst gensho-dry-hsl
  '((mono0   . (200   5  26))
    (mono1   . (200   5  30))
    (mono2   . (200   5  34))
    (mono3   . (200   5  38))
    (mono4   . (200   5  42))
    (mono5   . (200   5  46))
    (mono6   . (200   5  50))
    (mono7   . (200   5  54))
    (red     . (  0  55  49))
    (orange  . ( 30  55  49))
    (yellow  . ( 55  55  49))
    (green   . (130  55  49))
    (cyan    . (202  55  49))
    (blue    . (242  55  49))
    (purple  . (280  55  49))
    (magenta . (325  55  49))))

(defconst gensho-wet-hsl
  '((mono0   . (200   5  12))
    (mono1   . (200   5  19))
    (mono2   . (200   5  26))
    (mono3   . (200   5  33))
    (mono4   . (200   5  40))
    (mono5   . (200   5  47))
    (mono6   . (200   5  54))
    (mono7   . (200   5  61))
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
  mono0..mono7  (perceptual gray ramp; mono0 is background, mono7 foreground
                 for the chosen variant)
  red orange yellow green cyan blue purple magenta  (accent hues)

The returned colors respect `gensho-hsl-correction' (if non-zero).
For external tools / terminal emulators prefer `gensho-export-palette',
which maps to conventional ANSI/terminal color names (background, black,
brightblack, ...)."
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
  ;;                       highlights, matching regions, etc.
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
  ;; the treemacs sidebar) can be given a different step (mono1) via their
  ;; dedicated faces for a subtle layered "stone slab" effect.
  ;;
  ;; For the divider between such a panel and the main content, we set it to
  ;; the main content color (mono0). This produces a clean transition without
  ;; a visible seam line that would fight the plane expression — the
  ;; distinction comes from the tone difference (where present) and the
  ;; content itself. This choice was confirmed to give good slate feel after
  ;; direct testing.
  ;;
  ;; The small perceptual steps in the ramp are intentional for quiet texture;
  ;; they provide visible but not jarring layer separation. If an auxiliary
  ;; panel at mono1 feels noticeably different from main mono0, that is
  ;; expected with the current step size. In such cases it is common (and
  ;; de-facto friendly) to keep the sidebar at the same mono0 as main content
  ;; and let content structure + the clean divider treatment provide the
  ;; panel character.
  ;;
  ;; We keep normal editing buffers on the main mono0 plane. The main de-facto
  ;; signal for non-active windows is `mode-line-inactive` (set to mono1 here,
  ;; providing a gentle auxiliary-layer treatment at the chrome level).
  ;; A global subtle shift for every non-selected window is exactly what
  ;; `solaire-mode` is designed for. Because we prefer to stay close to
  ;; de-facto practices and avoid big contrast or external dependencies, the
  ;; theme itself does not force such a shift on regular buffers.
  ;;
  ;; Selected tab and current content deliberately share mono0 so the working
  ;; surface feels continuous, while chrome elements (bars, header) use higher
  ;; steps for layered separation. This is ramp layering as the primary
  ;; decoration, tuned for the cool low-sat stone image.
  ;;
  ;; See the "Gutter, dividers..." section and README for the current
  ;; practical choices and usage notes.

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
  ;;   tooltip bg changed to blue (cooler).
  ;; - org: table/habit-overdue/agenda-current-time/document-title/date
  ;;   shifted to mono/low to reduce "うるさい" colored text (core todo/done
  ;;   status kept as de facto).
  ;; - dired: dired-perm-write explicitly mono4+underline (low-key for
  ;;   permissions like lrwxr-xr-x, matching de facto patterns like solarized
  ;;   gray+underline; file/buffer supplementary info less noisy).
  ;; (Further s/l increase or frequency reduction possible after visual
  ;; confirmation; see below.)

  ;; Concretely, accents use s=55 (after minibuffer/org/dired freq reductions
  ;; for clutter) + l slightly below fg (49 dry / 57 wet) base. This (plus
  ;; heavy mono + :inherit) keeps the gray ramp dominant. The h assignments
  ;; and face definitions apply the survey patterns + specific rotenburo
  ;; reflection aesthetic. (s/l tweaks or frequency reduction possible later
  ;; -- see levers below.)

  (custom-theme-set-faces
   'gensho
   ;; --- Core primitives ---
   `(default ((,class (:foreground ,mono7 :background ,mono0))))
   `(fixed-pitch ((,class (:family unspecified))))
   `(variable-pitch ((,class (:family unspecified))))
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
   ;; Note on treemacs mono1: The step from main mono0 to mono1 is noticeable
   ;; (by design of the perceptual ramp for visible but quiet layers). If it
   ;; feels too strong compared to the main bg, you can override
   ;; `treemacs-window-background-face` to mono0 in your personal config; the
   ;; panel character will come from its distinct content, hl-line, and the
   ;; clean divider treatment.
   `(vertical-border ((,class (:foreground ,mono0))))
   `(region ((,class (:background ,mono1 :extend t))))
   `(highlight ((,class (:background ,mono1))))
   `(shadow ((,class (:foreground ,mono4))))
   `(match ((,class (:foreground ,mono0 :background ,green))))
   `(show-paren-match ((,class (:background ,mono1 :weight bold))))
   `(link ((,class (:foreground ,blue :underline t))))
   `(link-visited ((,class (:foreground ,purple :underline t))))
   `(error ((,class (:foreground ,red))))
   `(warning ((,class (:foreground ,yellow))))
   `(success ((,class (:foreground ,green))))
   `(minibuffer-prompt ((,class (:foreground ,mono6))))
   `(tooltip ((,class (:foreground ,mono7 :background ,blue))))

   ;; --- Modeline, header-line, tab-bar, tab-line (UI chrome) ---
   ;; Slate texture strategy: We differentiate "chrome layers" (bars, side
   ;; panels) from the main "content plane" using adjacent steps on the mono
   ;; ramp. This is the primary way to create visual depth and "stone slab"
   ;; feel in Emacs, which lacks heavy decorative primitives (borders, shadows,
   ;; titlebar gradients) available in other editors.
   ;; - tab-bar bg at mono2 (toolbar/frame chrome layer).
   ;; - Selected tab bg = mono0 (flushes with buffer default bg), so the active
   ;;   view surface is continuous from the tab "lid" down into the content.
   ;;   This creates the recessed/chiseled selection + unified chrome slab the
   ;;   user requested, evoking layered 玄昌石.
   ;; - Inactive tabs sit on the bar (mono1) with dimmer fg for clear but quiet
   ;;   distinction.
   ;; - tab-line (per-window) follows a similar but slightly more content-adjacent
   ;;   layering (bar at mono1) since it lives closer to buffer content.
   ;; - mode-line already uses mono2 (active chrome) and mono1 (inactive),
   ;;   harmonizing with the new tab-bar top bar.
   ;; See also the extended Mono ramp notes below.
   `(mode-line ((,class (:foreground ,mono7 :background ,mono2))))
   `(mode-line-inactive ((,class (:foreground ,mono6 :background ,mono1))))
   `(mode-line-buffer-id ((,class (:weight unspecified))))
   `(header-line ((,class (:foreground ,mono6 :background ,mono3 :weight unspecified))))
   `(tab-bar ((,class (:foreground ,mono7 :background ,mono2))))
   `(tab-bar-tab ((,class (:foreground ,mono7 :background ,mono0 :box unspecified))))
   `(tab-bar-tab-inactive ((,class (:foreground ,mono6 :background ,mono1))))
   `(tab-bar-tab-group-current ((,class (:inherit tab-bar-tab :weight bold))))
   `(tab-bar-tab-group-inactive ((,class (:inherit tab-bar-tab-inactive))))
   ;; tab-line (Emacs 28+ per-window buffer tabs)
   `(tab-line ((,class (:foreground ,mono7 :background ,mono1))))
   `(tab-line-tab ((,class (:foreground ,mono6 :background ,mono1))))
   `(tab-line-tab-current ((,class (:foreground ,mono7 :background ,mono0 :box unspecified))))
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
   ;; The step mono0 → mono1 is the smallest perceptual step we have (by design
   ;; of the ramp for visible but quiet layers). If the difference feels
   ;; noticeably large compared to main mono0, that is a common observation.
   ;; In that case, many users prefer to keep explicit sidebars on the same
   ;; mono0 as main content; the panel character then comes from the distinct
   ;; content (tree vs code), hl-line, icons, window shape, and the clean
   ;; (mono0) divider treatment. You can easily override
   ;; `treemacs-window-background-face` to mono0 in your own config if you
   ;; want less contrast while keeping the overall slate aesthetic.
   ;;
   ;; Non-focused windows in general:
   ;; Normal buffers stay on the main mono0 plane. The primary de-facto way
   ;; to signal "this window is not the active one" is through
   ;; `mode-line-inactive` (already set to mono1 here, which sits as a subtle
   ;; auxiliary-layer treatment at the chrome level without affecting editing
   ;; areas). A global "slightly towards mono1 for every non-selected window"
   ;; is precisely the use case `solaire-mode` was created for. Because we
   ;; want to stay close to de-facto practices and avoid big contrast or
   ;; external dependencies, the theme itself does not force such a shift on
   ;; normal buffers. If you like the solaire-like effect, using solaire-mode
   ;; is the recommended de-facto route (our controlled mono ramp works well
   ;; with it).
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
   `(orderless-match-face-0 ((,class (:weight unspecified :foreground ,cyan))))
   `(orderless-match-face-1 ((,class (:weight unspecified :foreground ,blue))))
   `(orderless-match-face-2 ((,class (:weight unspecified :foreground ,purple))))
   `(orderless-match-face-3 ((,class (:weight unspecified :foreground ,magenta))))
   `(consult-buffer ((,class (:foreground ,mono6))))
   `(consult-file ((,class (:foreground ,mono5))))
   `(corfu-default ((,class (:background ,mono1))))
   `(corfu-current ((,class (:foreground ,mono6 :background ,mono1))))
   `(corfu-bar ((,class (:background ,mono5))))

   ;; --- Navigation & project (dired, bookmark, etc.) ---
   `(dired-directory ((,class (:inherit font-lock-type-face))))
   `(dired-perm-write ((,class (:foreground ,mono4 :underline t))))
   `(bookmark-face ((,class (:foreground ,mono5 :distant-foreground ,mono5 :background unspecified))))
   `(deadgrep-filename-face ((,class (:inherit font-lock-builtin-face))))
   `(treemacs-root-face ((,class (:height unspecified))))
   ;; Slate sidebar: give the whole treemacs window a distinct layer (mono1)
   ;; so it reads as a side stone panel next to the main content plane (mono0).
   ;; With `vertical-border` at mono0, the transition is clean (no extra seam
   ;; line). The panel stands out through its tone + distinct content.
   ;; If the mono1 step feels strong vs main mono0, you can override this face
   ;; to mono0 in your config; distinction will come from content, hl-line,
   ;; and the clean divider.
   ;; hl-line uses the next step (mono2) for subtle selection without popping.
   ;; Directory uses the type face (cyan, low-pop structure per design notes);
   ;; files stay close to default/mono6 to keep the gray foundation dominant.
   ;; Git faces use semantic accents sparingly (matching dired/magit philosophy).
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
   ;; Weight/underline/italic provide intra-mono distinction (e.g. bold 'd'
   ;; for dir, underline for write), consistent with the low-key
   ;; dired-perm-write precedent (see above).  Leverages :inherit heavily
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
   `(marginalia-file-priv-write ((,class (:inherit shadow :underline t))))
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
   `(eglot-mode-line ((,class (:weight unspecified))))
   `(compilation-info ((,class (:weight unspecified))))
   `(compilation-mode-line-fail ((,class (:weight unspecified))))
   `(compilation-mode-line-exit ((,class (:weight unspecified))))

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
   `(org-headline-done ((,class (:foreground unspecified))))
   `(org-agenda-dimmed-todo-face ((,class (:inherit font-lock-comment-face))))
   `(org-todo ((,class (:inverse-video t :foreground ,red :background ,mono0))))
   `(org-done ((,class (:inverse-video t :foreground ,green :background ,mono0))))
   `(org-document-title ((,class (:foreground ,mono6 :weight bold))))
   `(org-column ((,class (:background ,mono2))))
   `(org-column-title ((,class (:inherit org-column))))
   `(org-table ((,class (:foreground ,mono6))))
   `(org-tag ((,class (:weight unspecified))))
   `(org-archived ((,class (:inherit org-headline-done))))
   `(org-drawer ((,class (:inherit font-lock-comment-face))))
   `(org-special-keyword ((,class (:inherit font-lock-comment-face))))
   `(org-date ((,class (:foreground ,mono5))))
   `(org-time-grid ((,class (:inherit font-lock-comment-face))))
   `(org-scheduled ((,class (:foreground ,mono6))))
   `(org-scheduled-today ((,class (:foreground ,mono6))))
   `(org-scheduled-previously ((,class (:foreground ,mono5))))
   `(org-upcoming-deadline ((,class (:inherit org-scheduled-previously))))
   `(org-agenda-structure ((,class (:foreground ,mono6 :weight unspecified))))
   `(org-agenda-current-time ((,class (:foreground ,mono6 :weight bold))))
   `(org-agenda-date-today ((,class (:foreground ,mono6 :weight bold))))
   `(org-agenda-date-weekend ((,class (:foreground ,mono4))))
   `(org-agenda-clocking ((,class (:slant italic))))
   `(org-habit-overdue-face ((,class (:background ,red))))
   `(org-roam-header-line ((,class (:inherit header-line))))
   `(org-noter-notes-exist-face ((,class (:foreground ,mono6))))
   `(org-noter-no-notes-exist-face ((,class (:foreground ,mono5))))
   `(deft-header-face ((,class (:inherit font-lock-builtin-face))))
   `(deft-title-face ((,class (:inherit font-lock-constant-face))))

   ;; --- Magit (Git porcelain; rich derived mode) ---
   ;; Follows design notes: "Org/Magit/Agenda and similar rich modes inherit the
   ;; font-lock and mono decisions heavily; hues only for key status indicators".
   ;; All specs use the variant-specific mono*/accent vars bound in the enclosing
   ;; let*, so no explicit dark/light branching is needed here (unlike many
   ;; magit deffaces).  This also fixes "floating" highlights/headers in gensho's
   ;; non-standard "light" variant (dry: still dark bg + light text, unlike
   ;; typical white-bg light themes).
   ;; Prefer :inherit + mono* over direct colors for harmony and DRY.
   ;; :extend t for full-width lines (Emacs 27+).
   `(magit-section-highlight ((,class (:background ,mono1 :extend t))))
   `(magit-section-heading ((,class (:inherit font-lock-keyword-face :weight bold))))
   `(magit-section-secondary-heading ((,class (:weight bold))))
   `(magit-section-heading-selection ((,class (:inherit magit-section-highlight :foreground ,orange :weight bold))))
   `(magit-diff-file-heading ((,class (:weight bold))))
   `(magit-diff-file-heading-highlight ((,class (:inherit magit-section-highlight :weight bold))))
   `(magit-diff-file-heading-selection ((,class (:inherit magit-diff-file-heading-highlight :foreground ,orange))))
   `(magit-diff-hunk-heading ((,class (:background ,mono2 :foreground ,mono6 :extend t))))
   `(magit-diff-hunk-heading-highlight ((,class (:background ,mono3 :foreground ,mono7 :extend t))))
   `(magit-diff-hunk-heading-selection ((,class (:inherit magit-diff-hunk-heading-highlight :foreground ,orange))))
   `(magit-diff-conflict-heading ((,class (:inherit magit-diff-hunk-heading))))
   `(magit-diff-revision-summary ((,class (:inherit magit-diff-hunk-heading))))
   `(magit-diff-lines-heading ((,class (:background ,orange :foreground ,mono0 :extend t))))
   `(magit-diff-context ((,class (:foreground ,mono5))))
   `(magit-diff-context-highlight ((,class (:background ,mono1 :foreground ,mono6 :extend t))))
   `(magit-diff-added ((,class (:background ,mono1 :foreground ,green :extend t))))
   `(magit-diff-added-highlight ((,class (:background ,mono2 :foreground ,green :extend t))))
   `(magit-diff-removed ((,class (:background ,mono1 :foreground ,red :extend t))))
   `(magit-diff-removed-highlight ((,class (:background ,mono2 :foreground ,red :extend t))))
   `(magit-diff-base ((,class (:background ,mono1 :foreground ,yellow :extend t))))
   `(magit-diff-base-highlight ((,class (:background ,mono2 :foreground ,yellow :extend t))))
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
   `(magit-blame-highlight ((,class (:background ,mono2 :extend t))))
   `(magit-blame-heading ((,class (:background ,mono2 :foreground ,mono6 :extend t
                                    :box (:color ,mono2 :line-width 2)))))
   `(magit-blame-summary ((,class (:foreground ,mono7))))
   `(magit-blame-hash ((,class (:foreground ,mono4))))
   `(magit-blame-name ((,class (:foreground ,mono6))))
   `(magit-blame-date ((,class (:foreground ,mono5))))

   ;; --- Calendar / eww (other apps) ---
   `(calendar-today ((,class (:inherit font-lock-warning-face))))
   `(calendar-weekend-header ((,class (:inherit font-lock-type-face))))
   `(eww-valid-certificate ((,class (:weight unspecified :foreground ,mono6))))))

(defconst gensho--export-name-map
  '((mono0   . background)
    (mono0   . brightcyan)
    (mono1   . black)
    (mono2   . brightblack)
    (mono3   . brightblue)
    (mono4   . brightgreen)
    (mono5   . white)
    (mono6   . brightyellow)
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
         ;; ANSI names in the 0-15 slot order for hex-list.
         (ordered-keys '(black red green yellow blue magenta cyan white
                               brightblack brightred brightgreen brightmagenta
                               brightblue brightyellow brightcyan brightwhite)))
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

