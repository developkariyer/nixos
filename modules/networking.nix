# Networking: NetworkManager, DNS resolution, SSH
{ config, lib, pkgs, ... }:

{
  # Configure network connections with nmcli or nmtui
  networking.networkmanager = {
    enable = true;
    wifi.powersave = false; # Prevents latency spikes on Intel iwlwifi
  };

  # DNS resolution
  services.resolved.enable = true;

  # SSH server
  services.openssh.enable = true;

  # Firewall (disabled by default, uncomment to configure)
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # networking.firewall.enable = false;
}
