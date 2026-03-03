# System services: fingerprint, keyring, Docker
{ config, lib, pkgs, ... }:

{
  # Fingerprint reader
  services.fprintd.enable = true;

  # GNOME Keyring for secrets
  services.gnome.gnome-keyring.enable = true;

  # Docker
  virtualisation.docker.enable = true;

  # direnv — auto-activates project devShells on cd
  programs.direnv.enable = true;

  # AnyDesk remote desktop (temporary — remove when done)
  environment.systemPackages = [ pkgs.anydesk ];
  systemd.services.anydesk = {
    description = "AnyDesk remote desktop daemon";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.anydesk}/bin/anydesk --service";
      Restart = "on-failure";
    };
  };

  # ydotoold — kernel-level input injection daemon for Wayland autoclicker
  programs.ydotool.enable = true;
}
