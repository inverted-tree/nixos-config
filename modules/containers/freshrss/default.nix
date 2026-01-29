# .               ___           _                                _
#  ___ ___ ___   |  _|___ ___ _| |    __ ___ ___ ___ ___ ___  __| |_ ___ ___
# |  _|_ -|_ -|  |  _| -_| -_| . |   |. | . | . |  _| -_| . ||. |  _| . |  _|
# |_| |___|___|  |_| |___|___|___|  |___|_  |_  |_| |___|_  |___| | |___|_|
#                                       |___|___|       |___|   |__|
# ──────────────────────────────────────────────────────────────────────────────
# A RSS feed aggregator with an API for third-party frontends.
#
# - Runs as a rootless Podman container managed via quadlet
# - Uses a dedicated unprivileged system user
# - Persists state on the host under /srv/freshrss
#
# Upstream documentation:
# https://www.freshrss.org/

{ lib, config, ... }@args:
let
  inherit (args) inputs;

  conf = config.modules.services.freshrss;
  service = "freshrss";
in
{
  imports = [
    ../../podman.nix
    inputs.sops-nix.nixosModules.sops
  ];

  options.modules.services.freshrss = {
    enable = lib.mkEnableOption "FreshRSS (rootless quadlet container)";

    publishPort = lib.mkOption {
      type = lib.types.port;
      default = 80;
      description = ''
        TCP port on which FreshRSS will be exposed on the host.

        This port is:
        - opened in the host firewall
        - published to the container as port 80
      '';
    };

    cronTime = lib.mkOption {
      type = lib.types.str;
      default = "*/15";
      description = ''
        CRON job time to fetch sources.

        Default is every fifteen minutes.
      '';
    };

    timeZone = lib.mkOption {
      type = lib.types.str;
      default = "Europe/Berlin";
      description = ''
        Time zone for the container process.

        Default is "Europe/Berlin".
      '';
    };
  };

  config = lib.mkIf conf.enable {
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
      "d /srv/${service} 0750 ${service} podman - -"
      "d /srv/${service}/data 0750 ${service} podman - -"
      "d /srv/${service}/extensions 0750 ${service} podman - -"
    ];

    networking.firewall.allowedTCPPorts = [ conf.publishPort ];

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
                    CRON_MIN = "${toString conf.cronTime}";
                  };
                  environmentFiles = [ "${secrets.freshrssEnv.path}" ];
                  volumes = [
                    "/srv/${service}/data:/var/www/FreshRSS/data:rw,U"
                    "/srv/${service}/extensions:/var/www/FreshRSS/extensions:rw,U"
                  ];
                  user = "0:0";
                  networks = [ "podman" ];
                  publishPorts = [ "${toString conf.publishPort}:80/tcp" ];
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
