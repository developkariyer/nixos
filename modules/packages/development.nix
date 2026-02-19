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

    # Antigravity IDE (temporary override — remove when upstream flake catches up)
    (inputs.antigravity-nix.packages.${pkgs.system}.default.overrideAttrs (old: rec {
      version = "1.18.3-4739469533380608";
      src = pkgs.fetchurl {
        url = "https://edgedl.me.gvt1.com/edgedl/release2/j0qc3/antigravity/stable/${version}/linux-x64/Antigravity.tar.gz";
        sha256 = "sha256-TH/kjJVOTSVcXT6kx08Wikpxh/0r7tsiNCPLV0gcljg=";
      };
    }))

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
