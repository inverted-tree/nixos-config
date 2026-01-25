# .              _ _           _                            _
#  _____ ___ ___|_| |_ ___ ___|_|___ ___     __ ___ ___ ___| |_
# |     | . |   | |  _| . |  _| |   | . |   |. | . | -_|   |  _|
# |_|_|_|___|_|_|_| | |___|_| |_|_|_|_  |  |___|_  |___|_|_| |
#                 |__|              |___|      |___|       |__|
# ──────────────────────────────────────────────────────────────────────────────
# Prometheus service for homelab monitoring and metrics collection
#
# - Runs as a rootless Podman container managed via quadlet
# - Uses a dedicated unprivileged system user
# - Persists time-series data on the host under /srv/prometheus
#
# Upstream documentation:
# https://prometheus.io/docs/

{ lib, config, ... }@args:
let
  inherit (args) inputs;

  conf = config.modules.services.prometheus;
  service = "prometheus";
in
{
  imports = [ ../../podman.nix ];

  options.modules.services.prometheus = {
    enable = lib.mkEnableOption "Prometheus (rootless quadlet container)";

    publishPort = lib.mkOption {
      type = lib.types.port;
      default = 9090;
      description = ''
        	TCP port on which Prometheus will be exposed on the host.

        	This port is:
        	- opened in the host firewall
        	- published to the container as port 9090
        	'';
    };

    configFile = lib.mkOption {
      type = lib.types.str;
      default = "/srv/prometheus/prometheus.yml";
      example = "/srv/prometheus/prometheus.yml";
      description = ''
        Path to the Prometheus configuration file on the host.

        If set, the file is mounted read-only into the container as `/etc/prometheus/prometheus.yml`.
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

    systemd.tmpfiles.rules = [
      "d /srv/${service}/data 0750 ${service} podman - -"
      "d ${builtins.dirOf conf.configFile} 0750 ${service} podman - -"
      "f ${conf.configFile} 0740 ${service} podman - -"
    ];

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
                  image = "docker.io/prom/prometheus:latest";
                  volumes = [
                    "/srv/${service}/data:/prometheus:idmap"
                    "${conf.configFile}:/etc/prometheus/prometheus.yml:ro"
                  ];
                  user = "0";
                  networks = [ "podman" ];
                  publishPorts = [ "${toString conf.publishPort}:9090" ];
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
