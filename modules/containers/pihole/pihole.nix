# .    _ _       _          _
#  ___|_| |_ ___| |___    _| |___ ___
# | . | |   | . | | -_|  | . |   |_ -|
# |  _|_|_|_|___|_|___|  |___|_|_|___|
# |_|
# ──────────────────────────────────────────────────────────────────────────────
# A DNS sinkhole to block unwanted contents on the entire network.
#   https://github.com/pi-hole/docker-pi-hole/#running-pi-hole-docker

{ config, ... }@args:
let
  inherit (args) inputs;
  service = "pihole";
in
{
  imports = [
    ../../podman.nix
    inputs.sops-nix.nixosModules.sops
  ];

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

  systemd.tmpfiles.rules = [ "d /srv/${service} 0770 ${service} podman - -" ];

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
                image = "docker.io/${service}/${service}:latest";
                environments = {
                  TZ = "Europe/Berlin";
                };
                environmentFiles = [ "${secrets.piholeEnv.path}" ];
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
}
