{
  description = "This flake manages all my nix machines.";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };
  outputs =
    inputs@{ self, nixpkgs, ... }:
    {
      # The itx server hosting most of my homelab.
      nixosConfigurations.itxserver = nixpkgs.lib.nixosSystem {
        modules = [ ./hosts/itxserver/configuration.nix ];
      };
    };
}
