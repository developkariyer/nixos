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

    # Antigravity IDE (temporary local build — remove when upstream flake catches up)
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
