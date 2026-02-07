# Development tools
{ pkgs, inputs, ... }:

{
  environment.systemPackages = with pkgs; [
    # IDE
    jetbrains.phpstorm

    # Version control
    git
    glab

    # Antigravity IDE
    inputs.antigravity-nix.packages.${pkgs.system}.default

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
    drawio
  ];
}
