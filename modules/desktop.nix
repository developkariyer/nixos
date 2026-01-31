# Desktop environment: Niri, SDDM, XDG portals, fonts
{ config, lib, pkgs, ... }:

{
  # Display manager
  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;

  # Niri compositor
  programs.niri.enable = true;

  # XDG portals for Wayland
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  # Wayland environment
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    SAL_USE_VCLPLUGIN = "gtk3";
  };

  # Fonts
  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
    nerd-fonts.droid-sans-mono
    corefonts
    vista-fonts
  ];

  # Enable dconf
  programs.dconf.enable = true;


}
