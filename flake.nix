{
  description = "OBSBOT camera control for NixOS";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
      };
    in {
      packages.${system} = {
        default = pkgs.callPackage ./package.nix {};
        obsbot-camera-control = self.packages.${system}.default;
      };

      overlays.default = final: prev: {
        obsbot-camera-control = final.callPackage ./package.nix {};
      };
    };
}
