# .              _ _           _                    _ _
#  _____ ___ ___|_| |_ ___ ___|_|___ ___    ___ _ _|_| |_ ___
# |     | . |   | |  _| . |  _| |   | . |  |_ -| | | |  _| -_|
# |_|_|_|___|_|_|_| | |___|_| |_|_|_|_  |  |___|___|_| | |___|
#                 |__|              |___|            |__|
# ──────────────────────────────────────────────────────────────────────────────
# Grafana service for homelab monitoring
#
# - Runs as a rootless Podman container managed via quadlet
# - Uses a dedicated unprivileged system user
# - Persists state on the host under /srv/grafana
#
# Upstream documentation:
# - https://grafana.com/docs/

{ lib, config, ... }@args:
let
  inherit (args) inputs;

  conf = config.modules.containers.grafana;
  service = "grafana";
in
{
  imports = [ ../../podman.nix ];

  options.modules.containers.grafana = {
    enable = lib.mkEnableOption "Grafana (rootless quadlet container)";

    publishPort = lib.mkOption {
      type = lib.types.port;
      default = 3000;
      description = ''
        TCP port on which Grafana will be exposed on the host.

        This port is:
        - opened in the host firewall
        - published to the container as port 3000
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
                  Description = "${service} podman container";

                  StartLimitIntervalSec = "180";
                  StartLimitBurst = "3";
                };

                containerConfig = {
                  image = "docker.io/grafana/grafana:latest";
                  volumes = [ "/srv/${service}:/var/lib/grafana:idmap" ];
                  user = "0:0";
                  networks = [ "host" ];
                  publishPorts = [ "${toString conf.publishPort}:3000" ];
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
