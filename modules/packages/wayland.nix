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
    ydotool       # kernel-level input injection (Wayland-compatible autoclicker)
    imagemagick   # pixel template matching for dialog detection
    xdotool       # X11 window automation (via XWayland for autoclicker)
  ];
}
