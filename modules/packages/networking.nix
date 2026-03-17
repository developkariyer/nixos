# Network tools
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    wireguard-tools
    openresolv
    ansible
    iw # WiFi diagnostics (link status, power save, scan)
  ];
}
