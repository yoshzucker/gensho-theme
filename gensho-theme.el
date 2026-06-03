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

;;; Code:

(require 'hsluv)
(require 'cl-lib)

(deftheme gensho
  "A dual light/dark theme inspired by 玄昌石 (Genshō stone) — dark elegance with a quiet, washed-stone light variant.")

(defconst gensho-dry-hsl
  '((mono0   . (200   5  26))
    (mono1   . (200   5  30))
    (mono2   . (200   5  34))
    (mono3   . (200   5  38))
    (mono4   . (200   5  42))
    (mono5   . (200   5  46))
    (mono6   . (200   5  50))
    (mono7   . (200   5  54))
    (red     . (  0 100  54))
    (orange  . ( 30 100  54))
    (yellow  . ( 70 100  54))
    (green   . (120 100  54))
    (cyan    . (210 100  54))
    (blue    . (250 100  54))
    (purple  . (290 100  54))
    (magenta . (320 100  54))))

(defconst gensho-wet-hsl
  '((mono0   . (200   5  12))
    (mono1   . (200   5  19))
    (mono2   . (200   5  26))
    (mono3   . (200   5  33))
    (mono4   . (200   5  40))
    (mono5   . (200   5  47))
    (mono6   . (200   5  54))
    (mono7   . (200   5  61))
    (red     . (  0 100  61))
    (orange  . ( 30 100  61))
    (yellow  . ( 60 100  61))
    (green   . (120 100  61))
    (cyan    . (210 100  61))
    (blue    . (250 100  61))
    (purple  . (290 100  61))
    (magenta . (320 100  61))))

(defun gensho--hex-palette (hsl-palette)
  "Convert HSL alist to hex alist using `hsluv-hsluv-to-hex'."
  (cl-loop for entry in hsl-palette
           for name = (car entry)
           for hsl = (cdr entry)
           collect `(,name . ,(hsluv-hsluv-to-hex hsl))))

(defconst gensho-dry
  (gensho--hex-palette gensho-dry-hsl))

(defconst gensho-wet
  (gensho--hex-palette gensho-wet-hsl))

;;;###autoload
(defun gensho-palette (&optional variant)
  "Return hex color alist for VARIANT or current `frame-background-mode'.
VARIANT is `wet' or `dry' (defaults from `frame-background-mode').

The alist uses the theme's internal semantic palette keys:
  mono0..mono7  (perceptual gray ramp; mono0 is background, mono7 foreground
                 for the chosen variant)
  red orange yellow green cyan blue purple magenta  (accent hues)

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
  ;; over high-contrast color pop. The concrete hue assignments and the
  ;; extensive use of mono + :inherit in the face settings below are
  ;; applications of the general patterns described above.

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
   `(tooltip ((,class (:foreground ,mono7 :background ,orange))))

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
   `(orderless-match-face-0 ((,class (:weight unspecified :foreground ,orange))))
   `(orderless-match-face-1 ((,class (:weight unspecified :foreground ,magenta))))
   `(orderless-match-face-2 ((,class (:weight unspecified :foreground ,green))))
   `(orderless-match-face-3 ((,class (:weight unspecified :foreground ,red))))
   `(consult-buffer ((,class (:foreground ,mono6))))
   `(consult-file ((,class (:foreground ,mono5))))
   `(corfu-default ((,class (:background ,mono1))))
   `(corfu-current ((,class (:foreground ,mono6 :background ,mono1))))
   `(corfu-bar ((,class (:background ,mono5))))

   ;; --- Navigation & project (dired, magit, etc.) ---
   `(dired-directory ((,class (:inherit font-lock-type-face))))
   `(treemacs-root-face ((,class (:height unspecified))))
   `(bookmark-face ((,class (:foreground ,mono5 :distant-foreground ,mono5 :background unspecified))))
   `(deadgrep-filename-face ((,class (:inherit font-lock-builtin-face))))

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
   `(org-document-title ((,class (:inherit font-lock-constant-face))))
   `(org-column ((,class (:background ,mono2))))
   `(org-column-title ((,class (:inherit org-column))))
   `(org-table ((,class (:foreground ,cyan))))
   `(org-tag ((,class (:weight unspecified))))
   `(org-archived ((,class (:inherit org-headline-done))))
   `(org-drawer ((,class (:inherit font-lock-comment-face))))
   `(org-special-keyword ((,class (:inherit font-lock-comment-face))))
   `(org-date ((,class (:inherit font-lock-type-face))))
   `(org-time-grid ((,class (:inherit font-lock-comment-face))))
   `(org-scheduled ((,class (:foreground ,green))))
   `(org-scheduled-today ((,class (:foreground ,mono6))))
   `(org-scheduled-previously ((,class (:foreground ,mono5))))
   `(org-upcoming-deadline ((,class (:inherit org-scheduled-previously))))
   `(org-agenda-structure ((,class (:foreground ,mono6 :weight unspecified))))
   `(org-agenda-current-time ((,class (:inherit font-lock-keyword-face))))
   `(org-agenda-date-today ((,class (:foreground ,mono6 :weight bold))))
   `(org-agenda-date-weekend ((,class (:foreground ,mono4))))
   `(org-agenda-clocking ((,class (:slant italic))))
   `(org-habit-overdue-face ((,class (:background ,purple))))
   `(org-roam-header-line ((,class (:inherit header-line))))
   `(org-noter-notes-exist-face ((,class (:foreground ,green))))
   `(org-noter-no-notes-exist-face ((,class (:foreground ,mono5))))
   `(deft-header-face ((,class (:inherit font-lock-builtin-face))))
   `(deft-title-face ((,class (:inherit font-lock-constant-face))))

   ;; --- Calendar / eww (other apps) ---
   `(calendar-today ((,class (:inherit font-lock-warning-face))))
   `(calendar-weekend-header ((,class (:inherit font-lock-type-face))))
   `(eww-valid-certificate ((,class (:weight unspecified :foreground ,green))))))

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
(when load-file-name
  (add-to-list 'custom-theme-load-path
               (file-name-directory load-file-name)))

(provide-theme 'gensho)
(provide 'gensho-theme)
;;; gensho-theme.el ends here
