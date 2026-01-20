# Browsers and communication apps
{ pkgs, ... }:

{
  programs.firefox.enable = true;

  environment.systemPackages = with pkgs; [
    chromium
    firefox
    google-chrome
    signal-desktop
    ferdium
  ];
}
