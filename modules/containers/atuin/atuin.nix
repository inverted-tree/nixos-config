# .    _       _ _    _   _     _
#  ___| |_ ___| | |  | |_|_|___| |_ ___ ___ _ _
# |_ -|   | -_| | |  |   | |_ -|  _| . |  _| | |
# |___|_|_|___|_|_|  |_|_|_|___| | |___|_| |_  |
#                              |__|        |___|
# ──────────────────────────────────────────────────────────────────────────────
# A searchable shell command history server to sync across my machines.
#   https://docs.atuin.sh/cli/

{ config, ... }@args:
let
  inherit (args) inputs;
  service = "atuin";
in
{
  imports = [
    ../../podman.nix
    inputs.sops-nix.nixosModules.sops
  ];

  sops.secrets = {
    atuinEnv = {
      sopsFile = ./${service}.env;
      format = "dotenv";
      owner = "${service}";
    };
  };

  users.groups.${service} = { };

  users.users.atuin = {
    group = "${service}";
    linger = true; # Required for the services start automatically without login
    isNormalUser = true; # Required for home-manager
    description = "Rootless user for the ${service} container";
    autoSubUidGidRange = true;
  };

  nix.settings.allowed-users = [ "${service}" ];

  systemd.tmpfiles.rules = [
    "d /srv/${service} 0770 ${service} podman - -"
    "d /srv/${service}/postgres 0770 ${service} podman - -"
    "d /srv/${service}/config 0770 ${service} podman - -"
  ];

  networking.firewall.allowedTCPPorts = [ 8888 ];

  home-manager.users.atuin =
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
            "${service}-db" = {
              unitConfig = {
                Description = "Atuin database podman container";
                StartLimitIntervalSec = "180";
                StartLimitBurst = "3";
              };

              containerConfig = {
                image = "docker.io/library/postgres:16.11-alpine3.23";
                environmentFiles = [ "${secrets.atuinEnv.path}" ];
                volumes = [ "/srv/${service}/postgres:/var/lib/postgresql/data:rw,U" ];
                networks = [ "podman" ];
              };

              serviceConfig = {
                Restart = "always";
                RestartSec = "10";
              };
            };

            "${service}-server" = {
              unitConfig = {
                Description = "Atuin-server podman container";
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
                  ATUIN_HOST = "0.0.0.0";
                  ATUIN_OPEN_REGISTRATION = "true";
                  RUST_LOG = "info,atuin_server=debug";
                };
                user = "0";
                environmentFiles = [ "${secrets.atuinEnv.path}" ];
                volumes = [ "/srv/${service}/config:/config:rw,U" ];
                networks = [ "podman" ];
                publishPorts = [ "8888:8888" ];
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
