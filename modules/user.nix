# User configuration: account, groups, shell aliases
{ config, lib, pkgs, ... }:

{
  users.users.ubuntu = {
    isNormalUser = true;
    extraGroups = [ "networkmanager" "wheel" "i2c" "docker" ];
    packages = with pkgs; [ tree ];
  };

  environment.shellAliases = {
    rebuild = "sudo nixos-rebuild switch --flake ~/Nixos-Setup#dell32";
    update = "nix flake update --flake ~/Nixos-Setup";
    nanoconf = "nano ~/Nixos-Setup/configuration.nix";
    nanoniri = "nano ~/Nixos-Setup/niri/config.kdl";
    nanoflake = "nano ~/Nixos-Setup/flake.nix";
  };
}
