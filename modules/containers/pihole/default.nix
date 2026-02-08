# .    _ _       _          _
#  ___|_| |_ ___| |___    _| |___ ___
# | . | |   | . | | -_|  | . |   |_ -|
# |  _|_|_|_|___|_|___|  |___|_|_|___|
# |_|
# ──────────────────────────────────────────────────────────────────────────────
# A DNS sinkhole to block unwanted contents on the entire network.
#
# - Runs as a rootless Podman container managed via quadlet
# - Uses a dedicated unprivileged system user
# - Persists state on the host under /srv/pihole
#
# Upstream documentation:
# - https://github.com/pi-hole/docker-pi-hole/#running-pi-hole-docker

{ lib, config, ... }@args:
let
  inherit (args) inputs;

  conf = config.modules.containers.pihole;
  service = "pihole";
in
{
  imports = [
    ../../podman.nix
    inputs.sops-nix.nixosModules.sops
  ];

  options.modules.containers.pihole = {
    enable = lib.mkEnableOption "PiHole (rootless quadlet container)";

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
      piholeEnv = {
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

    systemd.tmpfiles.rules = [ "d /srv/${service} 0750 ${service} podman - -" ];

    networking.firewall.allowedTCPPorts = [
      53
      80
      443
    ];

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
                  Description = "PiHole podman container";

                  StartLimitIntervalSec = "180";
                  StartLimitBurst = "3";
                };

                containerConfig = {
                  image = "docker.io/pihole/pihole:latest";
                  environments = {
                    TZ = "${conf.timeZone}";
                    FTLCONF_dns_listeningMode = "ALL";
                  };
                  environmentFiles = [ "${secrets.piholeEnv.path}" ];
                  user = "0:0";
                  volumes = [ "/srv/${service}:/etc/${service}:rw,U" ];
                  networks = [ "podman" ];
                  publishPorts = [
                    "53:53/tcp"
                    "53:53/udp"
                    "80:80/tcp"
                    "443:443/tcp"
                  ];
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
