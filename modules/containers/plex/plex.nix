# .    _                        _ _
#  ___| |___ _ _    _____ ___ _| |_| __    ___ ___ ___ _ _ ___ ___
# | . | | -_|_|_|  |     | -_| . | ||. |  |_ -| -_|  _| | | -_|  _|
# |  _|_|___|_|_|  |_|_|_|___|___|_|___|  |___|___|_|  \_/|___|_|
# |_|
# ──────────────────────────────────────────────────────────────────────────────
# The plex media server hosting my media (movies, TV shows and music).

{ config, ... }@args:
let
  inherit (args) inputs;
  service = "plex";
in
{
  imports = [
    ../../podman.nix
  ];

  users.groups.${service} = {
    gid = 990;
  };

  users.users."${service}" = {
    uid = 1002;
    group = "${service}";
    linger = true; # Required for the services start automatically without login
    isNormalUser = true; # Required for home-manager
    description = "Rootless user for the ${service} container";
    autoSubUidGidRange = true;
  };

  nix.settings.allowed-users = [ "${service}" ];

  systemd.tmpfiles.rules = [
    "d /srv/${service} 0750 ${service} podman - -"
    "d /srv/${service}/config 0750 ${service} podman - -"
    "d /srv/${service}/transcode 0750 ${service} podman - -"
  ];

  networking.firewall.allowedTCPPorts = [ 32400 ];

  home-manager.users."${service}" =
    { config, osConfig, ... }:
    {
      imports = [ inputs.quadlet-nix.homeManagerModules.quadlet ];

      virtualisation.quadlet =
        let
          inherit (config.virtualisation.quadlet) containers;
        in
        {
          containers = {
            "${service}" = {
              unitConfig = {
                Description = "${service} podman container";

                StartLimitIntervalSec = "180";
                StartLimitBurst = "3";
              };

              containerConfig = {
                image = "docker.io/plexinc/pms-docker:latest";

                environments = {
                  TZ = "Europe/Berlin";
                  ADVERTISE_IP =
                    let
                      addr0 = builtins.elemAt osConfig.networking.interfaces.enX0.ipv4.addresses 0;
                    in
                    "http://${addr0.address}:32400";
                  PUID = "0";
                  PGID = "0";
                };

                volumes = [
                  "/srv/${service}/config:/config:rw,U"
                  "/srv/${service}/transcode:/transcode:rw,U"
                  "/data/movies:/data/movies:ro"
                  "/data/music:/data/music:ro"
                ];

                publishPorts = [ "32400:32400" ];
              };

              serviceConfig = {
                Restart = "always";
                RestartSec = "10";
              };
            };
          };

          autoEscape = true;
        };

      home.stateVersion = "25.11";
    };
}
