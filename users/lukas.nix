{ config, pkgs, ... }:
{
  users.users.lukas = {
    isNormalUser = true;
    description = "Lukas";
    extraGroups = [
      "wheel"
      "docker"
      "syncthing"
    ];
    shell = pkgs.zsh;
    packages = with pkgs; [
      atuin
      bat
      cargo
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
      syncthing
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
    nix-ld = {
      enable = true;
      libraries = with pkgs; [
        glibc
        libgcc
      ];
    };
  };
}
