# .    _       _ _    _   _     _
#  ___| |_ ___| | |  | |_|_|___| |_ ___ ___ _ _
# |_ -|   | -_| | |  |   | |_ -|  _| . |  _| | |
# |___|_|_|___|_|_|  |_|_|_|___| | |___|_| |_  |
#                              |__|        |___|
# ──────────────────────────────────────────────────────────────────────────────
# A searchable shell command history server to sync across machines.
#
# - Runs a rootless Podman container managed via quadlet
# - Uses a dedicated unprivileged system user
# - Persists state in a sqlite3 database at /srv/atuin/atuin.db
#
# Upstream documentation:
# - https://docs.atuin.sh/cli/

{ lib, config, ... }@args:
let
  inherit (args) inputs;

  conf = config.modules.containers.atuin;
  service = "atuin";
in
{
  imports = [
    ../../podman.nix
  ];

  options.modules.containers.atuin = {
    enable = lib.mkEnableOption "Atuin (rootless quadlet container)";

    publishPort = lib.mkOption {
      type = lib.types.port;
      default = 8888;
      description = ''
        TCP port on which the Atuin server will be exposed on the host.

        This port is:
        - opened in the host firewall
        - published to the container as port 8888
      '';
    };

    configFile = lib.mkOption {
      type = lib.types.str;
      default = "/srv/atuin/server.toml";
      description = ''
        Path to the config file for atuin server.
      '';
    };

    openRegistration = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Determines whether Atuin will allow to register new users.
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

    home-manager.users.atuin =
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
                  Description = "Atuin podman container";

                  StartLimitIntervalSec = "180";
                  StartLimitBurst = "3";
                };

                containerConfig = {
                  image = "ghcr.io/atuinsh/atuin:18.10.0";
                  exec = [
                    "server"
                    "start"
                  ];
                  environments = {
                    ATUIN_DB_URI = "sqlite:///config/atuin.db";
                    ATUIN_HOST = "0.0.0.0";
                    ATUIN_OPEN_REGISTRATION = "${toString conf.openRegistration}";
                    RUST_LOG = "info,atuin_server=debug";
                  };
                  user = "0";
                  volumes = [
                    "/srv/${service}:/config:rw,U"
                    "${toString conf.configFile}:/config/server.toml:ro"
                  ];
                  networks = [ "podman" ];
                  publishPorts = [ "${toString conf.publishPort}:8888" ];
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
  };
}
