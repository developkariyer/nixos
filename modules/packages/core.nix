# Core system utilities
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    vim
    wget
    nano
    btop
    mc
    htop
    tmux
    ddcutil
  ];
}
