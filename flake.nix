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

    scripts.url = "path:./scripts";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      colmena,
      scripts,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      # Define a local nix-develop environment
      devShells.${system} = {
        # The default develop shell featuring colmena
        default = pkgs.mkShell {
          buildInputs = [ colmena.packages.${system}.colmena ];
        };
        # A separate develop shell featuring the generator tools
        mkTools = scripts.devShells.${system}.default;
      };
      # To be able to run the generator tools without entering a dev shell we
      #  export them as apps
      apps.${system} = {
        inherit (scripts.apps.${system}) mkHost mkSite mkUser;
      };

      # Manage the entire fleet with colmena
      colmenaHive = colmena.lib.makeHive {
        meta = {
          nixpkgs = import nixpkgs { inherit system; };
          specialArgs = { inherit inputs; };
        };

        # The itx server hosting most of my homelab
        alfa = {
          deployment = {
            targetHost = "100.89.38.72";
            targetUser = "lukas";
            tags = [ "homelab" ];
          };

          imports = [ ./hosts/alfa/default.nix ];
        };
      };

      # Although the whole fleet can be managed with colmena, I like to have a
      #   vanilla nixos fallback option in case colmena breaks.
      # ----------------------------------------------------------------------

      # The itx server hosting most of my homelab
      nixosConfigurations.alfa = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [ ./hosts/alfa/default.nix ];
      };
    };
}
