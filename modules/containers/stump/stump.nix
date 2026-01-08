# .       _           _      _ _ _
#  ___   | |_ ___ ___| |_   | |_| |_ ___  __ ___ _ _
# | -_|  | . | . | . | '_|  | | | . |  _||. |  _| | |
# |___|  |___|___|___|_|_|  |_|_|___|_| |___|_| |_  |
#                                               |___|
# ──────────────────────────────────────────────────────────────────────────────
# The main user for all systems. This is my standard admin login.

{ config, ... }@args:
let
  inherit (args) inputs;
  service = "stump";
in
{
  imports = [ ../../podman.nix ];

  users.groups.${service} = { };

  users.users.${service} = {
    group = "${service}";
    linger = true; # Required for the services start automatically without login
    isNormalUser = true; # Required for home-manager
    description = "Rootless user for the ${service} container";
    autoSubUidGidRange = true;
  };

  nix.settings.allowed-users = [ "${service}" ];

  systemd.tmpfiles.rules = [ "d /srv/${service} 0770 ${service} podman - -" ];

  networking.firewall.allowedTCPPorts = [ 10801 ];

  home-manager.users.${service} =
    { config, osConfig, ... }:
    {
      imports = [ inputs.quadlet-nix.homeManagerModules.quadlet ];

      virtualisation.quadlet =
        let
          inherit (config.virtualisation.quadlet) containers;
        in
        {
          containers = {
            ${service} = {
              unitConfig = {
                Description = "Stump Podman container";
              };

              containerConfig = {
                image = "docker.io/aaronleopold/stump:latest";
                exec = [ "" ];
                environments = {
                  STUMP_CONFIG_DIR = "/config";
                  RUST_BACKTRACE = "1";
                };
                volumes = [
                  "/srv/${service}:/config"
                  "/data/books:/data"
                ];
                uidMaps = [
                  "+%U:@%U"
                ]; # Map the user this container runs as into the container ns for mount access rights
                gidMaps = [ "+%G:@%G" ]; # The same for this users group
                user = "%U"; # Run the process as the user which owns the mounted directories
                networks = [ "podman" ];
                publishPorts = [ "10801:10801" ];
              };

              serviceConfig = {
                Restart = "always";
                RestartSec = "10";
              };
            };
          };

          autoEscape = true; # Automatically escape characters
        };

      home.stateVersion = "25.11";
    };
}
