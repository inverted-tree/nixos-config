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
      usbutils
      wget
      yazi
      zoxide
    ];
  };
}
