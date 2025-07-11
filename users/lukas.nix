{ config, pkgs, ... }: {
  users.users.lukas = {
    isNormalUser = true;
    description = "Lukas";
    extraGroups = [ "wheel" "docker" "syncthing" ];
    shell = pkgs.zsh;
    packages = with pkgs; [
      atuin
      bat
      cargo
      chezmoi
      fastfetch
      fzf
      fzf-zsh
      git
      lazygit
      python3
      starship
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
      libraries = with pkgs; [ glibc libgcc ];
    };
  };
}
