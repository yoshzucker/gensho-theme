# gensho-theme

A dark Emacs theme inspired by 玄昌石 (Genshō stone) — a deep, elegant black stone with subtle texture and quiet presence.

> **Note**: This theme is under active personal development. Expect frequent changes.

## Installation

### straight.el + use-package

```elisp
(use-package gensho-theme
  :straight (:host github :repo "yoshzucker/gensho-theme")
  :config
  (setq frame-background-mode 'dark)
  (load-theme 'gensho t))
```

## Usage

```elisp
(setq frame-background-mode 'dark)
(load-theme 'gensho t)
```

## Palette access

```elisp
(gensho-palette)
(gensho-export-palette 'json)
```

## License

MIT
