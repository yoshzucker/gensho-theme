# gensho-theme

A dark Emacs theme inspired by 玄昌石 (Genshō stone) — a deep, elegant black stone with subtle texture and quiet presence.

This is a personal theme under heavy development. The color palette and overall design are being actively rewritten.

> **Note**: Expect frequent breaking changes. When using from dotfiles with straight.el, pin to a specific commit or branch for stability.

## Installation (using develop branch for active work)

```elisp
(use-package gensho-theme
  :straight (:host github :repo "yoshzucker/gensho-theme" :branch "develop")
  :config
  (setq frame-background-mode 'dark)
  (load-theme 'gensho t))
```

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
