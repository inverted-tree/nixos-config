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
    colmena.url = "github:zhaofengli/colmena";
    sops-nix.url = "github:Mic92/sops-nix";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      colmena,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      # Define a local nix-develop environment
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = [ colmena.packages.${system}.colmena ];
      };

      # Manage the entire fleet with colmena
      colmenaHive = colmena.lib.makeHive {
        meta = {
          nixpkgs = import nixpkgs {
            inherit system;
          };
          specialArgs = { inherit inputs; };
        };

        # The itx server hosting most of my homelab
        alfa = {
          deployment = {
            targetHost = "100.89.38.72";
            targetUser = "lukas";
            tags = [ "homelab" ];
          };

          imports = [
            ./hosts/itxserver/configuration.nix
          ];
        };
      };

      # Although the whole fleet can be managed with colmena, I like to have a
      #   vanilla nixos fallback option in case colmena breaks.
      # ----------------------------------------------------------------------

      # The itx server hosting most of my homelab
      nixosConfigurations.alfa = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [ ./hosts/itxserver/configuration.nix ];
      };
    };
}
