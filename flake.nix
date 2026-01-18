{
  description = "NixOS configuration with Antigravity";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    antigravity-nix.url = "github:jacopone/antigravity-nix";
    noctalia.url = "github:noctalia-dev/noctalia-shell";
  };

  outputs = { self, nixpkgs, antigravity-nix, noctalia, ... }@inputs: {
    nixosConfigurations.dell32 = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; }; # This allows configuration.nix to see 'antigravity-nix'
      modules = [
        ./configuration.nix
        # Removed the 'antigravity-nix.nixosModules.default' line as it doesn't exist
      ];
    };
  };
}
