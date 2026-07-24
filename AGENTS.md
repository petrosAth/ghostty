# Ghostty package

The deployable configuration at `.config/ghostty` is an independent Git submodule. Its shader collections contain further submodules.

## Configuration contracts

- `.config/ghostty/config` provides a local Gruvbox fallback and then optionally loads `../theme/theme.conf` from the deployed XDG configuration. Keep the `?` prefix so a missing shared file is non-fatal.
- A selected theme basename must exist in `.config/ghostty/themes` and in the other consumers documented by `theme/AGENTS.md`.
- Relative shader paths are resolved from the deployed Ghostty configuration. Preserve disabled shader examples as comments and keep only the intended active shader uncommented.
- Do not edit third-party shader submodules as though they were ordinary files. Check their status before changing submodule pointers.

## Repository boundaries

Commit configuration work inside `.config/ghostty` before updating the parent dotfiles gitlink. Never reset or clean the nested repository implicitly.

## Verification

```sh
ghostty +validate-config --config-file=.config/ghostty/config
git -C .config/ghostty status --short
git -C .config/ghostty submodule status
```
