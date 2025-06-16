{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ../../users/lukas.nix
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
    ];
    firewall = {
      allowedTCPPorts = [ ];
      allowedUDPPorts = [ ];
    };
  };

  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = true;
  };

  environment.systemPackages = with pkgs; [
    btop
    curl
    gcc
    git
    gnumake
    nixfmt-rfc-style
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
  };

  programs = {
    zsh.enable = true;
  };

  system.stateVersion = "25.05";
}
