# .    _                    ___ _
#  ___|_|_ _    ___ ___ ___|  _|_|___
# |   | |_|_|  |  _| . |   |  _| | . |
# |_|_|_|_|_|  |___|___|_|_|_| |_|_  |
# .                              |___|
# ──────────────────────────────────────────────────────────────────────────────
# A central flake for deploying all nix-based systems across multiple sites.

{
  description = "Central flake for managing all nix deployments.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    sops-nix.url = "github:Mic92/sops-nix";
    nix-minecraft.url = "github:Infinidoge/nix-minecraft";
  };

  outputs =
    inputs@{ self, nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      # The itx server hosting most of my homelab.
      nixosConfigurations.itxserver = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [ ./hosts/itxserver/configuration.nix ];
      };

      nixosConfigurations.alfa = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [ ./hosts/s-alfa/default.nix ];
      };
    };
}
