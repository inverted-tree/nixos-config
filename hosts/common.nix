# .                                       _   _
#  ___ ___ _____ _____ ___ ___    ___ ___| |_|_|___ ___ ___
# |  _| . |     |     | . |   |  | . | . |  _| | . |   |_ -|
# |___|___|_|_|_|_|_|_|___|_|_|  |___|  _| | |_|___|_|_|___|
# .                                  |_| |__|
# ──────────────────────────────────────────────────────────────────────────────
# Defines options that are common across all host systems, be that servers or
#   clients.

{ pkgs, ... }:
{
  # This is the default locale for any machine
  i18n.defaultLocale = "en_US.UTF-8";

  # Common nix settings that apply to all machines
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

  # Basic packages that are nice to have on any machine with any user
  environment.systemPackages = with pkgs; [
    bat
    btop
    curl
    fastfetch
    git
    neovim
    nixfmt
    tmux
    tree
    wget
  ];
}
