{
  description = "NixOS configuration for additional things";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    antigravity-nix.url = "github:jacopone/antigravity-nix";
    noctalia.url = "github:noctalia-dev/noctalia-shell";
  };

  outputs = { self, nixpkgs, antigravity-nix, noctalia, ... }@inputs: {
#  outputs = { self, nixpkgs, noctalia, ... }@inputs: {
    nixosConfigurations.dell32 = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        ./configuration.nix
      ];
    };
  };
}
