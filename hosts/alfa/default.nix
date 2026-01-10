# .                               _ ___
#  ___ ___ ___ _ _ ___ ___     __| |  _| __
# |_ -| -_|  _| | | -_|  _|   |. | |  _||. |
# |___|___|_|  \_/|___|_|    |___|_|_| |___|
# ──────────────────────────────────────────────────────────────────────────────
# Defines the configuration for the central server ''alfa''. This server hosts
#   all the containerized services and serves the data.

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
    ./hardware.nix # The hardware-dependent options:
    ../common.nix # Common settings thath apply to all machines:
    ../../sites/theta.nix # Deployment-site specific options:
    # The users for this system:
    ../../users/lukas.nix
    ../../users/docker.nix
    # The custom modules:
    # ../../modules/containers/atuin.nix
    ../../modules/containers/stump/stump.nix
    ../../modules/containers/homeassistant.nix
    ../../modules/containers/plex.nix
    ../../modules/containers/freshrss.nix
    ../../modules/containers/pihole/pihole.nix
    # Any third-party modules or flakes:
    inputs.sops-nix.nixosModules.sops
  ];

  sops = {
    defaultSopsFormat = "dotenv";

    age.keyFile = "/home/lukas/.config/sops/age/keys.txt";

    secrets = {
      syncthing-user = {
        sopsFile = ../../secrets/syncthing.env.enc;
        key = "user";
      };
      syncthing-password = {
        sopsFile = ../../secrets/syncthing.env.enc;
        key = "password";
      };
    };
  };

  boot = {
    loader.grub = {
      enable = true;
      zfsSupport = true;
      efiSupport = true;
      efiInstallAsRemovable = true;
      mirroredBoots = [
        {
          devices = [ "nodev" ];
          path = "/boot";
        }
      ];
    };
    zfs.extraPools = [
      "zpool"
      "data"
    ];
  };

  networking = {
    hostName = "alfa";
    hostId = "1A0B35B6";
    networkmanager = {
      enable = true;
      unmanaged = [ "eno1" ];
    };
    useDHCP = false;
    interfaces = {
      eno1.ipv4.addresses = [
        {
          address = "10.0.0.10";
          prefixLength = 24;
        }
      ];
    };
    defaultGateway = {
      interface = "eno1";
    };
    nameservers = [
      "1.1.1.1"
      "1.0.0.1"
      "100.100.100.100"
    ];
    firewall = {
      allowedTCPPorts = [
        8123 # Home assistant web GUI
        8000
        8888
        32400 # Plex web GUI
        8384 # Syncthing web GUI
        22000 # Syncthing traffic
        8444
      ];
      allowedUDPPorts = [
        22000 # Syncthing traffic
        21027 # Syncthing discovery
      ];
    };
    search = [ "tabby-crocodile.ts.net" ];
  };

  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = true;
  };

  environment.systemPackages = with pkgs; [
    compose2nix
    gcc
    gnumake
    sops
    tailscale
  ];

  services = {
    zfs = {
      autoScrub.enable = true;
      autoSnapshot.enable = true;
    };
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
    fail2ban = {
      enable = true;
    };
    envfs.enable = true;
    tailscale.enable = true;
    syncthing = {
      enable = true;
      group = "syncthing";
      user = "lukas";
      dataDir = "/home/lukas/sync";
      configDir = "/home/lukas/.config/syncthing";
      overrideDevices = true;
      overrideFolders = true;
      settings = {
        gui = {
          user = config.sops.secrets.syncthing-user;
          password = config.sops.secrets.syncthing-password;
          address = "0.0.0.0:8384";
        };
        devices = {
          "MacBook-Pro" = {
            id = "GZAKPGB-BBVIY5T-2D3EY22-YYMGT5L-R3MNHGX-GYWNRWR-TG4BUMW-BQMBBAU";
          };
        };
        folders = {
          "Mobile Backups" = {
            path = "/data/backups/lukas/phone";
            devices = [ "MacBook-Pro" ];
          };
          "Documents" = {
            path = "/data/backups/lukas/documents";
            devices = [ "MacBook-Pro" ];
          };
          "Picture Archive" = {
            path = "/data/pictures/lukas/archive";
            devices = [ "MacBook-Pro" ];
          };
        };
      };
    };
  };

  programs = {
    zsh.enable = true;
    neovim.enable = true;
    neovim.defaultEditor = true;
  };

  system.stateVersion = "25.05";
}
