# ███╗   ███╗ █████╗ ██╗███╗   ██╗    ██╗   ██╗███████╗███████╗██████╗
# ████╗ ████║██╔══██╗██║████╗  ██║    ██║   ██║██╔════╝██╔════╝██╔══██╗
# ██╔████╔██║███████║██║██╔██╗ ██║    ██║   ██║███████╗█████╗  ██████╔╝
# ██║╚██╔╝██║██╔══██║██║██║╚██╗██║    ██║   ██║╚════██║██╔══╝  ██╔══██╗
# ██║ ╚═╝ ██║██║  ██║██║██║ ╚████║    ╚██████╔╝███████║███████╗██║  ██║
# ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝     ╚═════╝ ╚══════╝╚══════╝╚═╝  ╚═╝
# ═════════════════════════════════════════════════════════════════════
# The main user for all systems. This is the standard admin login.

{ config, pkgs, ... }: {
  users.users.lukas = {
    isNormalUser = true;
    description = "Lukas";
    extraGroups = [ "wheel" "docker" "syncthing" ];
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
      fzf-zsh
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
  };
  programs = {
    nix-ld = { # Needed to run unpatched dynamic binaries on NixOS.
      enable = true;
      libraries = with pkgs; [ glibc libgcc ]; # Required by some nvim plugins.
    };
  };
}
