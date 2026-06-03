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
;;   (gensho-export-palette 'json 'neon)  ; ANSI/terminal names for external tools

;;; Code:

(require 'hsluv)
(require 'cl-lib)

(deftheme gensho
  "A dual light/dark theme inspired by 玄昌石 (Genshō stone) — dark elegance with a quiet, washed-stone light variant.")

(defconst gensho-downpour-hsl
  '((mono0   . (260  20  86))
    (mono1   . (260  20  79))
    (mono2   . (260  20  72))
    (mono3   . (260  20  65))
    (mono4   . (260  20  58))
    (mono5   . (260  20  51))
    (mono6   . (260  20  44))
    (mono7   . (260  20  37))
    (red     . (  0 100  57))
    (orange  . ( 30 100  57))
    (yellow  . ( 70 100  57))
    (green   . (110 100  57))
    (cyan    . (200 100  57))
    (blue    . (250 100  57))
    (purple  . (280 100  57))
    (magenta . (310 100  57))))

(defconst gensho-neon-hsl
  '((mono0   . (240   5  12))
    (mono1   . (240   5  19))
    (mono2   . (240   5  26))
    (mono3   . (240   5  33))
    (mono4   . (240   5  40))
    (mono5   . (240   5  47))
    (mono6   . (240   5  54))
    (mono7   . (240   5  61))
    (red     . (  0  95  61))
    (orange  . ( 30  95  61))
    (yellow  . ( 70  95  61))
    (green   . (110  95  61))
    (cyan    . (200  95  61))
    (blue    . (250  95  61))
    (purple  . (280  95  61))
    (magenta . (310  95  61))))

(defun gensho--hex-palette (hsl-palette)
  "Convert HSL alist to hex alist using `hsluv-hsluv-to-hex'."
  (cl-loop for entry in hsl-palette
           for name = (car entry)
           for hsl = (cdr entry)
           collect `(,name . ,(hsluv-hsluv-to-hex hsl))))

(defconst gensho-downpour
  (gensho--hex-palette gensho-downpour-hsl))

(defconst gensho-neon
  (gensho--hex-palette gensho-neon-hsl))

;;;###autoload
(defun gensho-palette (&optional variant)
  "Return hex color alist for VARIANT or current `frame-background-mode'.
VARIANT is `neon' or `downpour' (defaults from `frame-background-mode').

The alist uses the theme's internal semantic palette keys:
  mono0..mono7  (perceptual gray ramp; mono0 is background, mono7 foreground
                 for the chosen variant)
  red orange yellow green cyan blue purple magenta  (accent hues)

For external tools / terminal emulators prefer `gensho-export-palette',
which maps to conventional ANSI/terminal color names (background, black,
brightblack, ...)."
  (let ((v (or variant
               (if (eq frame-background-mode 'light) 'downpour 'neon))))
    (if (eq v 'downpour) gensho-downpour gensho-neon)))

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

  ;; Mono ramp roles (perceptual steps from HSLuv; follow systematic gray
  ;; levels for visual hierarchy, e.g. adjacent steps for related elements).
  ;; 0: main bg / strong pop bg; 1: subtle bg (region etc.); 2: alt subtle;
  ;; 3: medium subtle; 4: faint; 5: comments/secondary; 6: prominent secondary;
  ;; 7: main fg.

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
   `(link ((,class (:foreground ,green :underline t))))
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
   `(font-lock-string-face ((,class (:foreground ,yellow))))
   `(font-lock-doc-face ((,class (:foreground ,mono4))))
   `(font-lock-keyword-face ((,class (:foreground ,purple))))
   `(font-lock-builtin-face ((,class (:foreground ,green))))
   `(font-lock-variable-name-face ((,class (:foreground ,blue))))
   `(font-lock-function-name-face ((,class (:foreground ,magenta))))
   `(font-lock-type-face ((,class (:foreground ,cyan))))
   `(font-lock-constant-face ((,class (:foreground ,orange))))
   `(font-lock-warning-face ((,class (:foreground ,red))))

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
   `(magit-section-heading ((,class (:foreground ,yellow :background ,mono1))))
   `(treemacs-root-face ((,class (:height unspecified))))
   `(bookmark-face ((,class (:distant-foreground ,blue :background unspecified))))
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
   `(org-scheduled-today ((,class (:foreground ,blue))))
   `(org-scheduled-previously ((,class (:foreground ,orange))))
   `(org-upcoming-deadline ((,class (:inherit org-scheduled-previously))))
   `(org-agenda-structure ((,class (:foreground ,green :weight unspecified))))
   `(org-agenda-current-time ((,class (:inherit font-lock-keyword-face))))
   `(org-agenda-date-today ((,class (:inherit font-lock-variable-name-face))))
   `(org-agenda-date-weekend ((,class (:inherit font-lock-type-face))))
   `(org-agenda-clocking ((,class (:slant italic))))
   `(org-habit-overdue-face ((,class (:background ,purple))))
   `(org-roam-header-line ((,class (:inherit header-line))))
   `(org-noter-notes-exist-face ((,class (:foreground ,green))))
   `(org-noter-no-notes-exist-face ((,class (:foreground ,orange))))
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
VARIANT is `neon' or `downpour' (defaults from `frame-background-mode')."
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
