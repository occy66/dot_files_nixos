# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

NixOS system configuration using Flakes + Home Manager. Manages one `x86_64-linux` host:
- **NIXOCCY** — laptop

## Key commands

Apply `.nix` changes (no package updates, fast):
```bash
sudo nixos-rebuild switch --flake . --impure
```
The host is auto-detected from the machine's hostname (`networking.hostName`).

Update all flake inputs then rebuild (equivalent to `apt upgrade`):
```bash
nix flake update
sudo nixos-rebuild switch --flake . --impure
```

Garbage-collect old generations:
```bash
sudo nix-collect-garbage -d
```

Dry-run to preview what would change without applying:
```bash
sudo nixos-rebuild dry-activate --flake .
```

## Architecture

```
flake.nix                              # inputs + nixosConfigurations.NIXOCCY
hosts/NIXOCCY/configuration.nix        # system-level config (boot, services, users, fonts, power management, backlight)
config/                                # dotfiles symlinked into $HOME via home.file (ghostty, lazygit, bat, eza, ruby, p10k, DankMaterialShell, claude)
home/home-laptop.nix                   # home-manager entry point
home/packages.nix                      # user packages
home/programs/                         # per-program config (-laptop.nix suffix, single-host leftover)
home/services/syncthing.nix            # syncthing user service
devenv-example/devenv.nix              # copy-paste template for Ruby on Rails projects
```

### Flake inputs

| Input | Purpose |
|---|---|
| `nixpkgs` (nixos-26.05 stable) | All packages |
| `home-manager` | User-level config, follows nixpkgs |
| `neovim-nightly-overlay` | Neovim nightly build |
| `dms` (DankMaterialShell/stable) | Sway shell/widget layer + greeter |

### Sibling repos auto-synced at rebuild

`home.activation.syncPrivate` clones (first run) or `git pull --ff-only` (subsequent runs):
- `crivotz/nubem_dot_files` → `~/.nubem_dot_files` (private: gitconfig, zsh_aliases, nubem_env, tmuxp)
- `crivotz/nv-ide` → `~/.nv-ide` (Neovim/LazyVim config)
- `crivotz/gcheck` → `~/.gcheck`

All other dotfiles (ghostty, lazygit, bat, eza, ruby, p10k, DankMaterialShell, claude statusline) live in `config/` inside this repo and are symlinked via `home.file`.

### LSP / Neovim

Mason is disabled. All LSPs and formatters are installed as Nix packages via `extraPackages` in `home/programs/neovim.nix`. To add an LSP, add the package there and rebuild.

### devenv (Ruby on Rails projects)

`devenv-example/devenv.nix` is a template. Copy it to a project root, add `.envrc` with `use devenv`, run `direnv allow`. It provisions per-project PostgreSQL + Redis and sets `DATABASE_URL`/`REDIS_URL` automatically.

## Display manager

Uses **dms-greeter** (`programs.dank-material-shell.greeter`, compositor default: `sway`). Built on greetd. Sway and Hyprland are both selectable as sessions at login.

Check module API with: `nix flake show github:AvengeMedia/DankMaterialShell/stable`

## Manual post-install steps

These must be done manually after a fresh install:

- **Syncthing**: open the web UI (`http://localhost:8384`) and pair with other devices
- **Atuin**: `atuin login` to sync shell history
- **GitHub CLI**: `gh auth login` to authenticate (needed by the activation script to clone private repos)

## Hardware-specific notes

- `hardware-configuration.nix` is machine-generated and read from `/etc/nixos/hardware-configuration.nix` (absolute path in `configuration.nix`), not in this repo.
- Monitor output names (`eDP-1`, `DP-1`, etc.) are configured in the sway program files. Use `wdisplays` to identify them.
