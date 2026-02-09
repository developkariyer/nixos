# Desktop applications (media, documents)
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    mpv
    imv
    zathura
    libreoffice-fresh
    adwaita-icon-theme
    hicolor-icon-theme
    papirus-icon-theme
    slack
  ];
}
