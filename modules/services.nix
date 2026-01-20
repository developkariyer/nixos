# System services: fingerprint, keyring, Docker
{ config, lib, pkgs, ... }:

{
  # Fingerprint reader
  services.fprintd.enable = true;

  # GNOME Keyring for secrets
  services.gnome.gnome-keyring.enable = true;

  # Docker
  virtualisation.docker.enable = true;
}
