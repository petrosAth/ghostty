# Ghostty Config

My personal [Ghostty](https://ghostty.org) terminal configuration.

## Layout

- `config` — main Ghostty config file (font, theme, window, cursor shader).
- `themes/` — color themes (Dracula, Gruvbox, Nord, Everforest, One Dark variants, etc.).
- `shaders/` — cursor and background shaders, including custom ones and three submodules:
  - [ghostty-shaders](https://github.com/0xhckr/ghostty-shaders)
  - [ghostty-cursor-shaders](https://github.com/sahaj-b/ghostty-cursor-shaders)
  - [ghostty-shader-playground](https://github.com/KroneCorylus/ghostty-shader-playground)

## Setup

Clone with submodules:

```sh
git clone --recurse-submodules <repo-url> ~/.config/ghostty
```

Or, if already cloned:

```sh
git submodule update --init --recursive
```
