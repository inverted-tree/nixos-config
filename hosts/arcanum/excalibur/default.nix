# .                _ _ _
#  ___ _ _ ___  __| |_| |_ _ _ ___
# | -_|_|_|  _||. | | | . | | |  _|
# |___|_|_|___|___|_|_|___|___|_|
# ──────────────────────────────────────────────────────────────────────────────
# Defines the configuration for the central server ''excalibur''. This server
#   lives on the arcanum cluster and hosts containerized services and data.

{
  config,
  lib,
  pkgs,
  ...
}@args:
let
  inherit (args) inputs;
in
{
  imports = [
    inputs.sops-nix.nixosModules.sops # Secrets management

    ./hardware.nix # Artifact specific hardware config
    ../common.nix # Common options for machines on this cluster

    ../../../users/lukas.nix # Admin user for this artifact
    ../../../modules # Service modules
    ../../../modules/containers/homeassistant/homeassistant.nix
    ../../../modules/containers/plex/plex.nix
  ];

  sops = {
    defaultSopsFormat = "dotenv";
    age.keyFile = "/home/lukas/.config/sops/age/keys.txt";
  };

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    zfs.extraPools = [ "data" ];
  };

  networking = {
    hostName = "excalibur";
    hostId = "1A0B35B6";
    networkmanager = {
      enable = true;
      unmanaged = [ "enX0" ];
    };
    useDHCP = false;
    interfaces = {
      enX0.ipv4.addresses = [
        {
          address = "10.0.0.11";
          prefixLength = 24;
        }
      ];
    };
    defaultGateway = {
      interface = "enX0";
    };
    nameservers = [
      "1.1.1.1"
      "1.0.0.1"
      "100.100.100.100"
    ];
  };

  environment.systemPackages = with pkgs; [
    sops
    tailscale
  ];

  services = {
    openssh = {
      enable = true;
      ports = [ 22 ];
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "no";
        AllowUsers = [ "lukas" ];
      };
    };
    tailscale.enable = true;
    zfs = {
      autoScrub.enable = true;
      autoSnapshot.enable = true;
    };
  };

  programs = {
    zsh.enable = true;
    neovim.enable = true;
  };

  modules.services = {
    prometheus = {
      enable = true;
      publishPort = 9090;
      configFile = "/srv/prometheus/prometheus.yml";
    };

    prometheus-node-exporter = {
      enable = true;
      publishPort = 9100;
    };
  };

  modules.containers = {
    atuin = {
      enable = true;
      publishPort = 8888;
      configFile = "/srv/atuin/server.toml";
      openRegistration = true;
    };

    freshrss = {
      enable = true;
      publishPort = 8008;
      cronTime = "*/15";
    };

    glance = {
      enable = true;
      publishPort = 8080;
      configFile = "/srv/glance/glance.yml";
    };

    grafana = {
      enable = true;
      publishPort = 3000;
    };

    pihole = {
      enable = true;
    };

    stump = {
      enable = true;
      publishPort = 10801;
    };
  };

  system.stateVersion = "25.05";
}
