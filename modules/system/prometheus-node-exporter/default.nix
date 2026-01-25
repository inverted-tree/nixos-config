# ._           _                _       _
# | |_ ___ ___| |_    _____ ___| |_ ___|_|___ ___
# |   | . |_ -|  _|  |     | -_|  _|  _| |  _|_ -|
# |_|_|___|___| |    |_|_|_|___| | |_| |_|___|___|
#             |__|             |__|
# ──────────────────────────────────────────────────────────────────────────────
# Prometheus node-exporter for host-level metrics collection
#
# - Exposes host hardware, OS, and kernel metrics
# - Intended to be scraped by a central Prometheus instance
#
# Upstream documentation:
# https://prometheus.io/docs/guides/node-exporter/
# https://wiki.nixos.org/wiki/Prometheus
# https://nixos.org/manual/nixos/stable/#module-services-prometheus-exporters

{ lib, config, ... }@args:
let
  inherit (args) inputs;

  conf = config.modules.services.prometheus-node-exporter;
  service = "prometheus-node-exporter";
in
{
  options.modules.services.${service} = {
    enable = lib.mkEnableOption "Prometheus Node-Exporter";

    publishPort = lib.mkOption {
      type = lib.types.port;
      default = 9100;
      description = ''
        	TCP port on which node-exporter will be exposed on the host.

        	This port is opened in the host firewall.
        	'';
    };
  };

  config = lib.mkIf conf.enable {
    networking.firewall.allowedTCPPorts = [ conf.publishPort ];

    services.prometheus.exporters.node = {
      enable = true;
      port = conf.publishPort;
      enabledCollectors = [
        "logind"
        "systemd"
      ];
      openFirewall = true;
    };
  };
}
