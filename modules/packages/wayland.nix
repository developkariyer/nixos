# Wayland/Niri native tools
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    alacritty
    fuzzel
    polkit_gnome
    networkmanagerapplet
    pavucontrol
    wl-clipboard
    libnotify
    kanshi
    wev
    nautilus
    grim
    slurp
    swappy
    xwayland-satellite
    seahorse
  ];
}
