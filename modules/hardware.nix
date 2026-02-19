# Hardware configuration: boot, graphics, i2c, power management
{ config, lib, pkgs, ... }:

{
  # Use the systemd-boot EFI boot loader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # DDC/CI backlight control
  boot.extraModulePackages = [ config.boot.kernelPackages.ddcci-driver ];
  boot.kernelModules = [ "ddcci_backlight" ];
  boot.kernelParams = [ "i915.enable_psr=0" "i915.enable_dc=0" "usbcode.autosuspend=-1" "resume_offset=42043392" ];

  # Swap file for hibernation (must be >= RAM)
  swapDevices = [{
    device = "/swapfile";
    size = 34 * 1024;  # 34 GB in MB
  }];

  # Resume from swap for hibernation (root partition that contains /swapfile)
  boot.resumeDevice = "/dev/disk/by-uuid/cbd3654c-de9f-46eb-820f-5180ae5d96be";

  # Hardware features
  hardware.i2c.enable = true;
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [ intel-media-driver ];
  };

  # Power management
  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;

  # Disable wakeup sources that abort hibernation
  powerManagement.powerDownCommands = ''
    # 1) ACPI wakeup table: toggle enabled S4 sources off
    for dev in GLAN RP01 PXSX RP06; do
      if grep -q "$dev.*enabled" /proc/acpi/wakeup; then
        echo "$dev" > /proc/acpi/wakeup
      fi
    done

    # 2) USB devices have independent wakeup via sysfs (e.g. iPad)
    for wakeup in /sys/bus/usb/devices/*/power/wakeup; do
      echo disabled > "$wakeup" 2>/dev/null || true
    done

    # 3) XHC (USB controller) PCI-level wakeup
    echo disabled > /sys/bus/pci/devices/0000:00:14.0/power/wakeup 2>/dev/null || true
  '';

  # Audio: PipeWire
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  services.pulseaudio.enable = false;
}
