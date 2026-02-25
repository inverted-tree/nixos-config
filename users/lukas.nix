# .          _
#  _____  __|_|___    _ _ ___ ___ ___
# |     ||. | |   |  | | |_ -| -_|  _|
# |_|_|_|___|_|_|_|  |___|___|___|_|
# ──────────────────────────────────────────────────────────────────────────────
# The main user for all systems. This is my standard admin login.

{ config, pkgs, ... }:
{
  users.users.lukas = {
    isNormalUser = true;
    description = "Lukas";
    extraGroups = [
      "wheel"
      "docker"
      "podman"
      "syncthing"
    ];
    linger = true; # Required for the services start automatically without login
    shell = pkgs.zsh;
    packages = with pkgs; [
      atuin
      bat
      cargo # For the command line tool. Is not used to install software.
      chezmoi
      clang-tools
      clippy
      fastfetch
      fzf
      git
      lazygit
      luarocks
      python3
      starship
      statix
      tmux
      tree
      unzip
      usbutils
      vimv
      wget
      yazi
      zoxide
    ];

    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII+XxyYGWZQOUr0QhYOXDfcVV/dTRakPzLwhCM+4Gk05"
    ];
  };

  programs = {
    nix-ld = {
      # Needed to run unpatched dynamic binaries on NixOS.
      enable = true;
      libraries = with pkgs; [
        glibc
        libgcc
      ]; # Required by some nvim plugins.
    };
  };

  nix.settings.allowed-users = [ "lukas" ];
}
