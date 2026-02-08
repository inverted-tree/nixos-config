# .  _         _   _                 _
#  _| | __ ___| |_| |_ ___  __ ___ _| |
# | . ||. |_ -|   | . | . ||. |  _| . |
# |___|___|___|_|_|___|___|___|_| |___|
# ──────────────────────────────────────────────────────────────────────────────
# Glance dashboard service offers an interfact for self-hosted services.
#
# - Runs as a rootless Podman container managed via quadlet
# - Uses a dedicated unprivileged system user
# - Needs a config file named glance.yml
#
# Upstream documentation:
# - https://github.com/glanceapp/glance

{ lib, config, ... }@args:
let
  inherit (args) inputs;

  conf = config.modules.containers.glance;
  service = "glance";
in
{
  imports = [
    ../../podman.nix
    inputs.quadlet-nix.nixosModules.quadlet
  ];

  options.modules.containers.glance = {
    enable = lib.mkEnableOption "Glance (rootless quadlet container)";

    publishPort = lib.mkOption {
      type = lib.types.port;
      default = 8080;
      description = ''
        TCP port on which Glance will be exposed on the host.

            This port is:
            - opened in the host firewall
            - published to the container as port 8080
      '';
    };

    configFile = lib.mkOption {
      type = lib.types.str;
      default = "/srv/glance/glance.yml";
      example = "/srv/glance/glance.yml";
      description = ''
        Path to the Glance configuration file on the host.

        If set, the file is mounted into the container as `/app/config/glance.yml`.
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
      "d /srv/${service} 0750 ${service} podman - -"
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
                  Description = "Stump Podman container";

                  StartLimitIntervalSec = "180";
                  StartLimitBurst = "3";
                };

                containerConfig = {
                  image = "docker.io/glanceapp/glance:latest";
                  volumes = [
                    "${conf.configFile}:/app/config/glance.yml:ro"
                  ];
                  networks = [ "podman" ];
                  publishPorts = [ "${toString conf.publishPort}:8080" ];
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
