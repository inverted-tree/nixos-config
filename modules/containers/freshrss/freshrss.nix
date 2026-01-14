# .               ___           _                                _
#  ___ ___ ___   |  _|___ ___ _| |    __ ___ ___ ___ ___ ___  __| |_ ___ ___
# |  _|_ -|_ -|  |  _| -_| -_| . |   |. | . | . |  _| -_| . ||. |  _| . |  _|
# |_| |___|___|  |_| |___|___|___|  |___|_  |_  |_| |___|_  |___| | |___|_|
#                                       |___|___|       |___|   |__|
# ──────────────────────────────────────────────────────────────────────────────
# A RSS feed aggregator with an API for third-party frontends.
#   https://www.freshrss.org/

{ config, ... }@args:
let
  inherit (args) inputs;
  service = "freshrss";
in
{
  imports = [
    ../../podman.nix
    inputs.sops-nix.nixosModules.sops
  ];

  sops.secrets = {
    freshrssEnv = {
      sopsFile = ./${service}.env;
      format = "dotenv";
      owner = "${service}";
    };
  };

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
    "d /srv/${service} 0770 ${service} podman - -"
    "d /srv/${service}/data 0770 ${service} podman - -"
    "d /srv/${service}/extensions 0770 ${service} podman - -"
  ];

  networking.firewall.allowedTCPPorts = [ 8008 ];

  home-manager.users.${service} =
    { config, osConfig, ... }:
    {
      imports = [ inputs.quadlet-nix.homeManagerModules.quadlet ];

      virtualisation.quadlet =
        let
          inherit (config.virtualisation.quadlet) containers;
          inherit (osConfig.sops) secrets;
        in
        {
          containers = {
            ${service} = {
              unitConfig = {
                Description = "FreshRSS podman container";

                StartLimitIntervalSec = "180";
                StartLimitBurst = "3";
              };

              containerConfig = {
                image = "docker.io/freshrss/freshrss";
                environments = {
                  TZ = "Europe/Berlin";
                  CRON_MIN = "*/15"; # Refresh feeds every 15 minutes
                };
                environmentFiles = [ "${secrets.freshrssEnv.path}" ];
                volumes = [
                  "/srv/${service}/data:/var/www/FreshRSS/data:rw,U"
                  "/srv/${service}/extensions:/var/www/FreshRSS/extensions:rw,U"
                ];
                user = "0:0";
                networks = [ "podman" ];
                publishPorts = [ "8008:80/tcp" ];
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
