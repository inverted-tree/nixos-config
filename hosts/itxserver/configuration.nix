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
    # Any other modules
    inputs.sops-nix.nixosModules.sops
  ];

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
        8888
        8123
      ];
      allowedUDPPorts = [ ];
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
  };

  programs = {
    zsh.enable = true;
    neovim.enable = true;
    neovim.defaultEditor = true;
  };

  system.stateVersion = "25.05";
}
