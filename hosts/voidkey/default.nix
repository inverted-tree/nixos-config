{ config, pkgs, ... }:

{
  imports = [
    ./hardware.nix
    ../../users/lukas.nix
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking = {
    hostName = "voidkey";
    hostId = "1A0C32B9";
  };

  environment.systemPackages = with pkgs; [
    git
    tree
  ];

  programs = {
    zsh.enable = true;
    neovim.enable = true;
    neovim.defaultEditor = true;
  };

  services = {
    xe-guest-utilities.enable = true;
    openssh = {
      enable = true;
      ports = [ 22 ];
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        AllowUsers = [ "lukas" ];
      };
    };
  };

  system.stateVersion = "25.05";
}
