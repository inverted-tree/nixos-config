# .       _           _      _ _ _
#  ___   | |_ ___ ___| |_   | |_| |_ ___  __ ___ _ _
# | -_|  | . | . | . | '_|  | | | . |  _||. |  _| | |
# |___|  |___|___|___|_|_|  |_|_|___|_| |___|_| |_  |
#                                               |___|
# ──────────────────────────────────────────────────────────────────────────────
# An e-book library to organize my textbooks.
#
# - Runs as a rootless Podman container managed via quadlet
# - Uses a dedicated unprivileged system user
# - Persists state on the host under /srv/stump
#
# Upstream documentation:
# - https://www.stumpapp.dev/

{ lib, config, ... }@args:
let
  inherit (args) inputs;

  conf = config.modules.containers.stump;
  service = "stump";
in
{
  imports = [ ../../podman.nix ];

  options.modules.containers.stump = {
    enable = lib.mkEnableOption "Stump (rootless quadlet container)";

    publishPort = lib.mkOption {
      type = lib.types.port;
      default = 10801;
      description = ''
        TCP port on which Stump will be exposed on the host.

        This port is:
        - opened in the host firewall
        - published to the container as port 10801
      '';
    };
  };

  config = lib.mkIf conf.enable {
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

    networking.firewall.allowedTCPPorts = [ conf.publishPort ];

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
                  # exec = [ "" ];
                  environments = {
                    STUMP_CONFIG_DIR = "/config";
                    RUST_BACKTRACE = "1";
                  };
                  volumes = [
                    "/srv/${service}:/config:idmap"
                    "/data/books:/data:ro"
                  ];
                  networks = [ "podman" ];
                  publishPorts = [ "${toString conf.publishPort}:10801" ];
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
  };
}
