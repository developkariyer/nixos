# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A declarative NixOS system configuration for a Dell laptop (hostname: `dell32`) using Nix flakes. Target: x86_64-linux, NixOS 26.05.

## Common Commands

```bash
# Apply configuration changes
sudo nixos-rebuild switch --flake .#dell32

# Build without applying (dry run / test)
sudo nixos-rebuild build --flake .#dell32

# Update all flake inputs
nix flake update --flake .

# Garbage collection
nix-collect-garbage -d
```

Shell aliases defined in `modules/user.nix`:
- `rebuild` → `sudo nixos-rebuild switch --flake ~/Nixos-Setup#dell32`
- `update` → `nix flake update --flake ~/Nixos-Setup`
- `nn` / `nf` / `nr` → quick nano edits of configuration.nix / flake.nix / niri config

## Architecture

```
flake.nix               # Entry point; defines inputs + dell32 NixOS output
configuration.nix       # Imports all modules, sets hostname/timezone
hardware-configuration.nix  # Auto-generated; kernel modules, filesystems, swap
modules/
  hardware.nix          # Boot (systemd-boot), Intel graphics, PipeWire audio, hibernate
  desktop.nix           # SDDM display manager, Niri (Wayland compositor), fonts, XDG portals
  networking.nix        # NetworkManager (WiFi powersave off), systemd-resolved, SSH
  services.nix          # fprintd, GNOME Keyring, Docker, direnv, AnyDesk, ydotool
  user.nix              # User "ubuntu" with group memberships and shell aliases
  android.nix           # Android Studio + KVM acceleration
  packages/
    core.nix            # CLI essentials (vim, btop, tmux, ddcutil)
    networking.nix      # wireguard-tools, ansible, iw
    wayland.nix         # alacritty, fuzzel, grim/slurp, nautilus, wl-clipboard
    browsers.nix        # Firefox, Chromium, Chrome, Signal, Ferdium
    development.nix     # PHPStorm, Antigravity IDE, Claude Code, Go toolchain, gh/glab
    desktop.nix         # mpv, LibreOffice, GIMP, Slack, icon themes
    noctalia.nix        # Noctalia shell + Qt5 effects
devshells/
  hubcr/                # Node.js 20 dev environment
  sybita/               # Node.js 22 dev environment
  vscode-extension/     # VS Code extension dev environment
.config/
  niri/config.kdl       # Niri compositor keybindings, layouts, animations
  noctalia/settings.json
  autoretry/            # Template images for ydotool autoclicker
```

## Pinned Inputs & Known Constraints

- **antigravity-nix**: Pinned to v1.18.4 (not 1.19.6) — upstream has a bwrap double-mount bug; patched with `sed` in flake.nix
- **noctalia**: Pinned to commit `d4941da` — newer versions have a QML regression
- **flake.lock**: Check `git diff flake.lock` after `nix flake update` to review what changed before rebuilding

## Hardware Notes

- **Hibernate**: Uses `shutdown` mode (not `platform`) to avoid Dell ACPI spurious wakeup events
- **WiFi**: Powersave disabled in NetworkManager to prevent latency spikes on Intel iwlwifi
- **Backlight**: DDC/CI via `ddcci_driver` kernel module + `ddcutil` CLI
- **Swap**: 34GB swapfile required for hibernation support

## Dev Environments

`direnv` is enabled system-wide — entering a `devshells/` subdirectory automatically loads its Nix dev shell. No manual `nix develop` needed.
