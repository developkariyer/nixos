# Networking: NetworkManager, DNS resolution, SSH
{ config, lib, pkgs, ... }:

{
  # Configure network connections with nmcli or nmtui
  networking.networkmanager = {
    enable = true;
    wifi.powersave = false; # Prevents latency spikes on Intel iwlwifi
    unmanaged = [ "eno2" ];
  };

  # DNS resolution
  services.resolved.enable = true;

  # SSH server
  services.openssh.enable = true;

  # Static IP on eno2 for local network
  networking.interfaces.eno2.ipv4.addresses = [{
    address = "10.0.0.1";
    prefixLength = 24;
  }];

  # Firewall (disabled by default, uncomment to configure)
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # networking.firewall.enable = false;
}
