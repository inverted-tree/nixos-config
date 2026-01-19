{ config, pkgs, ... }:

{
  imports = [
    ./hardware.nix
    ../../users/lukas.nix
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

  system.stateVersion = "25.05";
}
