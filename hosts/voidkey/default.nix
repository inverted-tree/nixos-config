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
    ./hardware.nix
    ../common.nix
    ../../sites/theta.nix
    ../../users/lukas.nix
  ];

  boot = {
    loader.grub = {
      enable = true;
      efiSupport = true;
      efiInstallAsRemovable = true;
      mirroredBoots = [
        {
          devices = [ "nodev" ];
          path = "/boot";
        }
      ];
    };
  };

  networking = {
    hostName = "voidkey";
    useDHCP = true;
    nameservers = [
      "1.1.1.1"
      "1.0.0.1"
      "100.100.100.100"
    ];
  };

  environment.systemPackages = with pkgs; [
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
    envfs.enable = true;
  };

  programs = {
    zsh.enable = true;
    neovim.enable = true;
    neovim.defaultEditor = true;
  };

  system.stateVersion = "25.05";
}
