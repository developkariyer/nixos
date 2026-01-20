# Desktop applications (media, documents)
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    mpv
    imv
    zathura
    libreoffice-fresh
  ];
}
