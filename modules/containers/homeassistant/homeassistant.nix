# _                                _     _           _
# | |_ ___ _____ ___     __ ___ ___|_|___| |_  __ ___| |_
# |   | . |     | -_|   |. |_ -|_ -| |_ -|  _||. |   |  _|
# |_|_|___|_|_|_|___|  |___|___|___|_|___| | |___|_|_| |
#                                        |__|        |__|
# ──────────────────────────────────────────────────────────────────────────────
# A customizable home automation suite.
#   https://www.home-assistant.io/installation/alternative/

{ config, ... }@args:
let
  inherit (args) inputs;
  service = "homeassistant";
in
{
  imports = [ ../../podman.nix ];

  systemd.tmpfiles.rules = [
    "d /srv/${service} 0750 root podman - -"
    "d /srv/${service}/config 0750 root podman - -"
  ];

  networking.firewall.allowedTCPPorts = [ 8123 ];

  # Since homeassistant needs to interface with different host devices,
  #   I'll run it from system root for now.
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
            image = "ghcr.io/home-assistant/home-assistant:stable";
            environments = {
              TZ = "Europe/Berlin";
            };
            volumes = [
              "/srv/${service}/config:/config:idmap"
              "/etc/localtime:/etc/localtime:ro"
              "/run/dbus:/run/dbus:ro"
            ];
            devices = [
              "/dev/serial/by-id/usb-ITEAD_SONOFF_Zigbee_3.0_USB_Dongle_Plus_V2_20220708102723-if00"
            ];
            networks = [ "host" ];

            publishPorts = [ "8123:8123" ];
          };

          serviceConfig = {
            Restart = "always";
            RestartSec = "10";
          };
        };
      };

      autoEscape = true; # Automatically escape characters
    };
}
