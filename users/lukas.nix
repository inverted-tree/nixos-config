{ config, pkgs, ... }:
{
  users.users.lukas = {
    isNormalUser = true;
    description = "Lukas";
    extraGroups = [
      "wheel"
      "docker"
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
      neovim
      python3
      starship
      syncthing
      tree
      usbutils
      wget
      yazi
      zoxide
    ];
  };
}
