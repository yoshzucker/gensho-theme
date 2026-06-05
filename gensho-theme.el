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
   `(vertical-border ((,class (:foreground ,mono2))))
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

   ;; --- Modeline, header-line, tab-bar (UI chrome) ---
   `(mode-line ((,class (:foreground ,mono7 :background ,mono2))))
   `(mode-line-inactive ((,class (:foreground ,mono6 :background ,mono1))))
   `(mode-line-buffer-id ((,class (:weight unspecified))))
   `(header-line ((,class (:foreground ,mono6 :background ,mono3 :weight unspecified))))
   `(tab-bar ((,class (:foreground ,mono7 :background ,mono0))))
   `(tab-bar-tab ((,class (:foreground ,mono7 :background ,mono2 :box unspecified))))
   `(tab-bar-tab-inactive ((,class (:foreground ,mono6 :background ,mono1))))

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

