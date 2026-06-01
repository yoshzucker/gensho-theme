;;; gensho-theme.el --- Gensho theme: dark elegance of 玄昌石 -*- lexical-binding: t; -*-

;; Author: yoshzucker
;; Maintainer: yoshzucker
;; Version: 0.1.0
;; Package-Requires: ((emacs "27.1") (hsluv "1.0"))
;; Keywords: faces, themes, gensho, stone, dark
;; Homepage: https://github.com/yoshzucker/gensho-theme
;; License: MIT

;;; Commentary:

;; Dark theme inspired by 玄昌石 (Genshō stone).
;;
;; Usage (standalone):
;;   (setq frame-background-mode 'dark)
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
;;   (gensho-palette)
;;   (gensho-export-palette 'json 'neon)  ; for external tools

;;; Code:

(require 'hsluv)
(require 'cl-lib)

(deftheme gensho
  "A dark theme inspired by 玄昌石 (Genshō stone).")

(defconst gensho-downpour-hsl
  '((background    . (260  20  87))
    (brightwhite   . (260  20  77))
    (white         . (260  20  67))
    (brightblack   . (260  20  57))
    (black         . (260  20  47))
    (foreground    . (260  20  37))
    (red           . (  0 100  57))
    (yellow        . ( 70 100  57))
    (green         . (110 100  57))
    (cyan          . (200 100  57))
    (blue          . (250 100  57))
    (magenta       . (310 100  57))
    (brightred     . ( 30 100  57))
    (brightmagenta . (280 100  57))
    (brightyellow  . (  0  55  57))
    (brightgreen   . (110  55  57))
    (brightcyan    . (250  55  57))
    (brightblue    . (280  55  57))))

(defconst gensho-neon-hsl
  '((background    . (260  55  13))
    (black         . (260  55  23))
    (brightblack   . (260  55  33))
    (white         . (260  55  43))
    (brightwhite   . (260  55  53))
    (foreground    . (260  55  63))
    (red           . (  0 100  63))
    (yellow        . ( 70 100  63))
    (green         . (110 100  63))
    (cyan          . (200 100  63))
    (blue          . (250 100  63))
    (magenta       . (310 100  63))
    (brightred     . ( 30 100  63))
    (brightmagenta . (280 100  63))
    (brightyellow  . (  0  55  63))
    (brightgreen   . (110  55  63))
    (brightcyan    . (250  55  63))
    (brightblue    . (280  55  63))))

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
For external tools, prefer `gensho-export-palette'."
  (let ((v (or variant
               (if (eq frame-background-mode 'light) 'downpour 'neon))))
    (if (eq v 'downpour) gensho-downpour gensho-neon)))

(let* ((class '((class color) (min-colors 89)))
       (colors (gensho-palette))
       (background    (alist-get 'background    colors))
       (foreground    (alist-get 'foreground    colors))
       (red           (alist-get 'red           colors))
       (green         (alist-get 'green         colors))
       (yellow        (alist-get 'yellow        colors))
       (blue          (alist-get 'blue          colors))
       (magenta       (alist-get 'magenta        colors))
       (cyan          (alist-get 'cyan           colors))
       (white         (alist-get 'white          colors))
       (brightred     (alist-get 'brightred     colors))
       (brightgreen   (alist-get 'brightgreen   colors))
       (brightyellow  (alist-get 'brightyellow  colors))
       (brightmagenta (alist-get 'brightmagenta colors))
       (brightcyan    (alist-get 'brightcyan    colors))

       (lightp (eq frame-background-mode 'light))
       (background-near (alist-get (if lightp 'brightwhite 'black) colors))
       (background-far  (alist-get (if lightp 'white 'brightblack) colors))
       (foreground-far  (alist-get (if lightp 'brightblack 'white) colors))
       (foreground-near (alist-get (if lightp 'black 'brightwhite) colors))
       (primary         (alist-get (if lightp 'brightcyan 'brightblue) colors))
       (secondary       (alist-get 'blue colors)))

  (custom-theme-set-faces
   'gensho
   ;; --- Core ---
   `(default ((,class (:foreground ,foreground :background ,background))))
   `(fixed-pitch ((,class (:family unspecified))))
   `(variable-pitch ((,class (:family unspecified))))
   `(fringe ((,class (:background ,background))))
   `(border ((,class (:background ,background))))
   `(vertical-border ((,class (:foreground ,background-near))))
   `(internal-border ((,class (:background ,background))))
   `(mode-line ((,class (:foreground ,background :background ,primary))))
   `(mode-line-inactive ((,class (:foreground ,primary :background ,background-near))))
   `(mode-line-buffer-id ((,class (:weight unspecified))))
   `(header-line ((,class (:foreground ,primary :background ,background-far :weight unspecified))))
   `(minibuffer-prompt ((,class (:foreground ,primary))))
   `(cursor ((,class (:background ,primary))))
   `(region ((,class (:background ,background-near :extend t))))
   `(highlight ((,class (:background ,background-near))))
   `(show-paren-match ((,class (:background ,background-near :weight bold))))
   `(link ((,class (:foreground ,brightgreen :underline t))))
   `(link-visited ((,class (:foreground ,green :underline t))))
   `(shadow ((,class (:foreground ,white))))
   `(match ((,class (:foreground ,background :background ,brightgreen))))
   `(warning ((,class (:foreground ,yellow))))
   `(error ((,class (:foreground ,red))))
   `(success ((,class (:foreground ,green))))
   `(tooltip ((,class (:foreground ,foreground :background ,brightyellow))))

   ;; --- Font-lock ---
   `(font-lock-comment-face ((,class (:foreground ,white :slant italic))))
   `(font-lock-string-face ((,class (:foreground ,yellow))))
   `(font-lock-doc-face ((,class (:foreground ,white))))
   `(font-lock-keyword-face ((,class (:foreground ,brightmagenta))))
   `(font-lock-builtin-face ((,class (:foreground ,green))))
   `(font-lock-variable-name-face ((,class (:foreground ,blue))))
   `(font-lock-function-name-face ((,class (:foreground ,magenta))))
   `(font-lock-type-face ((,class (:foreground ,cyan))))
   `(font-lock-constant-face ((,class (:foreground ,brightred))))
   `(font-lock-warning-face ((,class (:foreground ,red))))

   ;; --- Tab bar ---
   `(tab-bar ((,class (:foreground ,foreground :background ,background))))
   `(tab-bar-tab ((,class (:foreground ,background :background ,primary :box unspecified))))
   `(tab-bar-tab-inactive ((,class (:foreground ,primary :background ,background-near))))

   ;; --- Completion & search (modern) ---
   `(vertico-current ((,class (:background ,background-near))))
   `(orderless-match-face-0 ((,class (:weight unspecified :foreground ,brightred))))
   `(orderless-match-face-1 ((,class (:weight unspecified :foreground ,magenta))))
   `(orderless-match-face-2 ((,class (:weight unspecified :foreground ,green))))
   `(orderless-match-face-3 ((,class (:weight unspecified :foreground ,red))))
   `(consult-buffer ((,class (:foreground ,foreground-near))))
   `(consult-file ((,class (:foreground ,foreground-far))))
   `(corfu-default ((,class (:background ,background))))
   `(corfu-current ((,class (:foreground ,primary :background ,background-near))))
   `(corfu-bar ((,class (:background ,primary))))

   ;; --- Search / jump ---
   `(isearch ((,class (:foreground ,background :background ,brightyellow))))
   `(lazy-highlight ((,class (:foreground ,background :background ,brightcyan))))
   `(avy-lead-face ((,class (:foreground ,background :background ,blue))))
   `(avy-lead-face-0 ((,class (:foreground ,background :background ,brightred))))
   `(avy-lead-face-1 ((,class (:foreground ,background :background ,red))))
   `(avy-lead-face-2 ((,class (:foreground ,background :background ,magenta))))

   ;; --- Evil / misc ---
   `(evil-snipe-first-match-face ((,class (:background ,background-far))))
   `(deadgrep-filename-face ((,class (:inherit font-lock-builtin-face))))

   ;; --- Major packages ---
   `(magit-section-heading ((,class (:foreground ,yellow :background ,background))))
   `(eglot-mode-line ((,class (:weight unspecified))))
   `(dired-directory ((,class (:inherit font-lock-type-face))))
   `(treemacs-root-face ((,class (:height unspecified))))
   `(bookmark-face ((,class (:distant-foreground ,blue :background unspecified))))

   ;; --- Outline / org (core + rich) ---
   `(outline-1 ((,class (:inherit font-lock-type-face))))
   `(outline-2 ((,class (:inherit font-lock-variable-name-face))))
   `(outline-3 ((,class (:inherit font-lock-constant-face))))
   `(outline-4 ((,class (:inherit font-lock-builtin-face))))
   `(outline-5 ((,class (:inherit font-lock-function-name-face))))
   `(outline-6 ((,class (:inherit font-lock-string-face))))
   `(outline-7 ((,class (:inherit font-lock-warning-face))))
   `(outline-8 ((,class (:inherit font-lock-keyword-face))))

   `(org-headline-done ((,class (:foreground unspecified))))
   `(org-agenda-dimmed-todo-face ((,class (:inherit font-lock-comment-face))))
   `(org-todo ((,class (:inverse-video t :foreground ,red :background ,background))))
   `(org-done ((,class (:inverse-video t :foreground ,green :background ,background))))
   `(org-document-title ((,class (:inherit font-lock-constant-face))))
   `(org-column ((,class (:background ,background-near))))
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
   `(org-scheduled-previously ((,class (:foreground ,brightred))))
   `(org-upcoming-deadline ((,class (:inherit org-scheduled-previously))))
   `(org-agenda-structure ((,class (:foreground ,green :weight unspecified))))
   `(org-agenda-current-time ((,class (:inherit font-lock-keyword-face))))
   `(org-agenda-date-today ((,class (:inherit font-lock-variable-name-face))))
   `(org-agenda-date-weekend ((,class (:inherit font-lock-type-face))))
   `(org-agenda-clocking ((,class (:slant italic))))
   `(org-habit-overdue-face ((,class (:background ,brightmagenta))))
   `(org-roam-header-line ((,class (:inherit header-line))))
   `(org-noter-notes-exist-face ((,class (:foreground ,green))))
   `(org-noter-no-notes-exist-face ((,class (:foreground ,brightred))))
   `(deft-header-face ((,class (:inherit font-lock-builtin-face))))
   `(deft-title-face ((,class (:inherit font-lock-constant-face))))

   ;; --- Calendar / compile / ein / eww ---
   `(calendar-today ((,class (:inherit font-lock-warning-face))))
   `(calendar-weekend-header ((,class (:inherit font-lock-type-face))))
   `(compilation-info ((,class (:weight unspecified))))
   `(compilation-mode-line-fail ((,class (:weight unspecified))))
   `(compilation-mode-line-exit ((,class (:weight unspecified))))
   `(ein:cell-input-area ((,class (:background ,background-near))))
   `(ein:cell-input-prompt ((,class (:foreground ,background :background ,primary))))
   `(ein:cell-output-prompt ((,class (:foreground ,background :background ,secondary))))
   `(eww-valid-certificate ((,class (:weight unspecified :foreground ,green))))))

;;;###autoload
(defun gensho-export-palette (format &optional variant)
  "Export the palette for external tools.
FORMAT is `json', `alist', or `hex-list'.
VARIANT is `neon' or `downpour' (defaults from `frame-background-mode')."
  (let* ((palette (gensho-palette variant))
         (ordered-keys '(black red green yellow blue magenta cyan white
                               brightblack brightred brightgreen brightyellow
                               brightblue brightmagenta brightcyan brightwhite
                               background foreground)))
    (pcase format
      ('alist
       palette)
      ('hex-list
       (mapcar (lambda (k) (alist-get k palette)) ordered-keys))
      ('json
       (let ((json-pairs
              (mapconcat
               (lambda (k)
                 (let ((v (alist-get k palette)))
                   (format "  %S: %S" (symbol-name k) v)))
               ordered-keys
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
