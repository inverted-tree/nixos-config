# A default nixos configuration to build a new system from.
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
    # All custom modules
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
    hostName = "<HOSTNAME>";
    hostId = "<SOME_RANDOM_8_CHARS>";
    networkmanager.enable = true;
    useDHCP = true;
    nameservers = [
      "1.1.1.1"
      "1.0.0.1"
      "100.100.100.100"
    ];
    firewall = {
      allowedTCPPorts = [ ];
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
    git
    tailscale
    tree
    vim
  ];

  services = {
    openssh = {
      enable = true;
      ports = [ 22 ];
      settings = {
        PasswordAuthentication = true;
        KbdInteractiveAuthentication = true;
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
