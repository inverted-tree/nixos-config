#                                       _         _
#   __ ___ ___  __ ___ _ _ _____    ___| |_ _ ___| |_ ___ ___
#  |. |  _|  _||. |   | | |     |  |  _| | | |_ -|  _| -_|  _|
# |___|_| |___|___|_|_|___|_|_|_|  |___|_|___|___| | |___|_|
#                                                |__|
# ──────────────────────────────────────────────────────────────────────────────
# Defines options that are common across all artifacts on the arcanum cluster.

{ pkgs, ... }:
{
  i18n.defaultLocale = "en_US.UTF-8";

  time.timeZone = "Europe/Berlin";

  boot = {
    supportedFilesystems = [ "zfs" ];
    zfs.forceImportRoot = false;
  };

  networking = {
    defaultGateway = {
      address = "10.0.0.1";
    };
  };

  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      auto-optimise-store = true;
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

  environment.systemPackages = with pkgs; [
    bat
    btop
    curl
    fastfetch
    git
    nixfmt-rfc-style
    tmux
    tree
    wget
  ];

  programs = {
    neovim.enable = true;
    neovim.defaultEditor = true;
  };

  services = {
    xe-guest-utilities.enable = true;
  };
}
