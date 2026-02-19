# Main NixOS configuration for dell32
# Run: sudo nixos-rebuild switch --flake .#dell32

{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./modules/hardware.nix
    ./modules/desktop.nix
    ./modules/networking.nix
    ./modules/services.nix
    ./modules/user.nix
    ./modules/android.nix

    # Packages by category
    ./modules/packages/core.nix
    ./modules/packages/networking.nix
    ./modules/packages/wayland.nix
    ./modules/packages/browsers.nix
    ./modules/packages/development.nix
    ./modules/packages/desktop.nix
    ./modules/packages/noctalia.nix
  ];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Host-specific settings
  networking.hostName = "dell32";
  time.timeZone = "Europe/Berlin";

  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Automatic garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  # https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion
  system.stateVersion = "26.05";
}
