# Network tools
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    wireguard-tools
    openresolv
    ansible
  ];
}
