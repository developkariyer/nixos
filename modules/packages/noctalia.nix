# Noctalia shell and dependencies
{ pkgs, inputs, ... }:

{
  environment.systemPackages = with pkgs; [
    inputs.noctalia.packages.${pkgs.system}.default
    libsForQt5.qt5.qtgraphicaleffects
  ];
}
