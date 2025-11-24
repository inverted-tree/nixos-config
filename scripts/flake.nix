{
  description = "Infrastructure helper scripts (mkHost, mkSite, mkUser)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs, ... }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in {
      packages = forAllSystems (system:
        let pkgs = import nixpkgs { inherit system; };
        in {
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
        });

      apps = forAllSystems (system: {
        mkHost = {
          type = "app";
          program = "${self.packages.${system}.mkHost}/bin/mkHost";
          meta = {
            description =
              "Generate a new host scaffold (hardware + config template)";
          };
        };

        mkSite = {
          type = "app";
          program = "${self.packages.${system}.mkSite}/bin/mkSite";
          meta = { description = "Site generator (not implemented yet)"; };
        };

        mkUser = {
          type = "app";
          program = "${self.packages.${system}.mkUser}/bin/mkUser";
          meta = { description = "User generator (not implemented yet)"; };
        };
      });

      devShells = forAllSystems (system:
        let pkgs = import nixpkgs { inherit system; };
        in {
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
        });
    };
}

