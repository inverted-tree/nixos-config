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
    # The hardware-dependent options
    ./hardware-configuration.nix
    # All (shared/non-specific) users
    ../../users/lukas.nix
    ../../users/docker.nix
    # All custom modules
    ../../modules/containers/stump.nix
    ../../modules/containers/homeassistant.nix
    ../../modules/containers/plex.nix
    ../../modules/containers/freshrss.nix
    # Any other modules
    inputs.sops-nix.nixosModules.sops
  ];

  sops = {
    defaultSopsFormat = "dotenv";
    age.keyFile = "/home/lukas/.config/sops/age/keys.txt";
    secrets.syncthing-user = {
      sopsFile = ../../secrets/syncthing.env.enc;
      key = "user";
    };
    secrets.syncthing-password = {
      sopsFile = ../../secrets/syncthing.env.enc;
      key = "password";
    };
  };

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  time.timeZone = "Europe/Berlin";

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
    zfs.extraPools = [ "zpool" ];
  };

  networking = {
    hostName = "itxserver";
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
      address = "10.0.0.1";
      interface = "eno1";
    };
    nameservers = [
      "1.1.1.1"
      "1.0.0.1"
      "100.100.100.100"
    ];
    firewall = {
      allowedTCPPorts = [
        8123
        8888
        32400
        8384 # Syncthing web GUI
        22000 # Syncthing traffic
      ];
      allowedUDPPorts = [
        22000 # Syncthing traffic
        21027 # Syncthing discovery
      ];
    };
    search = [ "tabby-crocodile.ts.net" ];
  };

  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = true;
  };

  environment.systemPackages = with pkgs; [
    btop
    compose2nix
    curl
    gcc
    git
    gnumake
    nixfmt-rfc-style
    sops
    tailscale
    tree
    vim
    wget
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
