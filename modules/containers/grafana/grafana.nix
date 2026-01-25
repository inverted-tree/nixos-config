# .              _ _           _                    _ _
#  _____ ___ ___|_| |_ ___ ___|_|___ ___    ___ _ _|_| |_ ___
# |     | . |   | |  _| . |  _| |   | . |  |_ -| | | |  _| -_|
# |_|_|_|___|_|_|_| | |___|_| |_|_|_|_  |  |___|___|_| | |___|
#                 |__|              |___|            |__|
# ──────────────────────────────────────────────────────────────────────────────
# A service to monitor all homelab services. https://grafana.com/docs/

{ config, ... }@args:
let
  inherit (args) inputs;
  service = "grafana";
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

  networking.firewall.allowedTCPPorts = [ 3000 ];

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
                Description = "Grafana podman container";

                StartLimitIntervalSec = "180";
                StartLimitBurst = "3";
              };

              containerConfig = {
                image = "docker.io/grafana/grafana:latest";
                volumes = [
                  "/srv/${service}:/var/lib/grafana:idmap"
                ];
                user = "0";
                networks = [ "podman" ];
                publishPorts = [ "3000:3000" ];
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
