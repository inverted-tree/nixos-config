# .              _ _           _                            _
#  _____ ___ ___|_| |_ ___ ___|_|___ ___     __ ___ ___ ___| |_
# |     | . |   | |  _| . |  _| |   | . |   |. | . | -_|   |  _|
# |_|_|_|___|_|_|_| | |___|_| |_|_|_|_  |  |___|_  |___|_|_| |
#                 |__|              |___|      |___|       |__|
# ──────────────────────────────────────────────────────────────────────────────
# A service to monitor all homelab services. https://prometheus.io/docs/

{ config, ... }@args:
let
  inherit (args) inputs;
  service = "prometheus";
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

  systemd.tmpfiles.rules = [
    "d /srv/${service} 0750 ${service} podman - -"
    "d /srv/${service}/data 0750 ${service} podman - -"
    "f /srv/${service}/prometheus.yml 0740 ${service} podman - -"
  ];

  networking.firewall.allowedTCPPorts = [ 9090 ];

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
                  "/srv/${service}/prometheus.yml:/etc/prometheus/prometheus.yml:idmap"
                  "/srv/${service}/data:/prometheus:idmap"
                ];
                user = "0";
                networks = [ "podman" ];
                publishPorts = [ "9090:9090" ];
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
