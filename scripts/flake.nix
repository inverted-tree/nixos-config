# ._     ___            _       _
# |_|___|  _|___  __   | |_ ___| |___ ___ ___ ___
# | |   |  _|  _||. |  |   | -_| | . | -_|  _|_ -|
# |_|_|_|_| |_| |___|  |_|_|___|_|  _|___|_| |___|
# .                              |_|
# ──────────────────────────────────────────────────────────────────────────────
# This flake exposes the infrastructure helper scripts (mkHost, mkSite, mkUser,
#  mkPods) to the nix-ecosystem.
{
  description = "Infrastructure helper scripts (mkHost, mkSite, mkUser, mkPods)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs, ... }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          mkHost = pkgs.writeShellApplication {
            name = "mkHost";

            runtimeInputs = [
              pkgs.vim
              pkgs.gettext
              pkgs.nixos-install-tools
              pkgs.coreutils
              pkgs.util-linux
            ];

            text = builtins.readFile ./mkHost.sh;
          };

          mkSite = pkgs.writeShellApplication {
            name = "mkSite";
            text = builtins.readFile ./mkSite.sh;
            checkPhase = "true";
          };

          mkUser = pkgs.writeShellApplication {
            name = "mkUser";
            text = builtins.readFile ./mkUser.sh;
            checkPhase = "true";
          };

          mkPods = pkgs.writeShellApplication {
            name = "mkPods";

            runtimeInputs = [
              pkgs.vim
              pkgs.compose2nix
              pkgs.gettext
              pkgs.nixos-install-tools
              pkgs.coreutils
              pkgs.util-linux
            ];

            text = builtins.readFile ./mkPods.sh;
          };
        }
      );

      apps = forAllSystems (system: {
        mkHost = {
          type = "app";
          program = "${self.packages.${system}.mkHost}/bin/mkHost";
          meta = {
            description = "Generate a new host scaffold (hardware + config template)";
          };
        };

        mkSite = {
          type = "app";
          program = "${self.packages.${system}.mkSite}/bin/mkSite";
          meta = {
            description = "Site generator (not implemented yet)";
          };
        };

        mkUser = {
          type = "app";
          program = "${self.packages.${system}.mkUser}/bin/mkUser";
          meta = {
            description = "User generator (not implemented yet)";
          };
        };

        mkPods = {
          type = "app";
          program = "${self.packages.${system}.mkPods}/bin/mkPods";
          meta = {
            description = "Generate a new podman container/pod module from a docker compose file";
          };
        };
      });

      devShells = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          default = pkgs.mkShell {
            packages = [
              pkgs.bashInteractive
              pkgs.gettext
              pkgs.nixos-install-tools
              pkgs.shellcheck
              pkgs.nixpkgs-fmt
              pkgs.git
            ];
          };
        }
      );
    };
}
