# Hardware configuration: boot, graphics, i2c, power management
{ config, lib, pkgs, ... }:

{
  # Use the systemd-boot EFI boot loader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Hardware features
  hardware.i2c.enable = true;
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [ intel-media-driver ];
  };

  # Power management
  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;
}
