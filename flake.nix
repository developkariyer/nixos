{
  description = "NixOS configuration for additional things";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    antigravity-nix.url = "github:jacopone/antigravity-nix";
    # Pinned: d4941da has QML regression ("Non-existent attached object" in MainScreen.qml)
    noctalia.url = "github:noctalia-dev/noctalia-shell/5137c5efcac31d9aee6952b99f1dcaec9966fe21";
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
