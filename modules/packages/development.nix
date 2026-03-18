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

    # Antigravity IDE (Patched for bwrap 0.11.0 double-mount bug)
    (pkgs.symlinkJoin {
      name = "antigravity-patched";
      paths = [ inputs.antigravity-nix.packages.${pkgs.system}.default ];
      postBuild = ''
        # Remove the read-only symlink created by symlinkJoin
        rm $out/bin/antigravity
        
        # Copy the actual wrapper script so we can modify it
        cp ${inputs.antigravity-nix.packages.${pkgs.system}.default}/bin/antigravity $out/bin/antigravity
        
        # Make it writable so sed can edit it
        chmod +w $out/bin/antigravity
        
        # Strip the redundant bwrap mount lines causing the crash
        sed -i '/opengl-driver/d' $out/bin/antigravity
      '';
    })

    inputs.claude-code-nix.packages.${pkgs.system}.claude-code

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
    # drawio  # temporarily disabled — Yarn CDN ECONNRESET
  ];
}

