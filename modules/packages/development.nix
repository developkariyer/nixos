# Development tools
{ pkgs, inputs, ... }:

{
  environment.systemPackages = with pkgs; [
    # IDE
    jetbrains.phpstorm

    # Version control
    git
    glab
    gh

    # Antigravity IDE (temporary local build — upstream flake stuck at 1.16.5)
    # When jacopone/antigravity-nix updates to >= 1.18.3:
    #   1. Replace line below with: inputs.antigravity-nix.packages.${pkgs.system}.default
    #   2. Delete ./antigravity-custom.nix
    #   3. Run: nix flake update antigravity-nix --flake ~/Nixos-Setup
    (pkgs.callPackage ./antigravity-custom.nix {})

    # OpenCode AI terminal assistant
    opencode

    # Go development
    go
    gopls
    delve

    # Containers
    docker-compose

    # Database
    mariadb.client

    # Utilities
    jq
    gnumake
    drawio
  ];
}
