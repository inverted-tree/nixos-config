# .       _           _      _ _ _
#  ___   | |_ ___ ___| |_   | |_| |_ ___  __ ___ _ _
# | -_|  | . | . | . | '_|  | | | . |  _||. |  _| | |
# |___|  |___|___|___|_|_|  |_|_|___|_| |___|_| |_  |
#                                               |___|
# ──────────────────────────────────────────────────────────────────────────────
# An e-book library to organize my textbooks. https://www.stumpapp.dev/

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

  systemd.tmpfiles.rules = [ "d /srv/${service} 0750 ${service} podman - -" ];

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

                StartLimitIntervalSec = "180";
                StartLimitBurst = "3";
              };

              containerConfig = {
                image = "docker.io/aaronleopold/stump:latest";
                exec = [ "" ];
                environments = {
                  STUMP_CONFIG_DIR = "/config";
                  RUST_BACKTRACE = "1";
                };
                volumes = [
                  "/srv/${service}:/config:idmap"
                  "/data/books:/data:ro"
                ];
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
