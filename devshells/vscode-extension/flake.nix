{
  description = "VS Code extension development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        packages = [
          pkgs.nodejs_20
          pkgs.nodePackages.typescript
          pkgs.nodePackages.typescript-language-server
          pkgs.vsce
          pkgs.esbuild
        ];

        shellHook = ''
          echo "🧩 VS Code Extension devshell loaded"
          echo "  node:  $(node --version)"
          echo "  tsc:   $(tsc --version)"
          echo "  vsce:  $(vsce --version 2>/dev/null || echo 'available')"
          echo ""
          echo "Scaffold new extension:  npx --yes yo generator-code"
          echo "Package extension:       vsce package"
          echo "Publish extension:       vsce publish"
        '';
      };
    };
}
