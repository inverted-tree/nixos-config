# A default user configuration template.
{ config, pkgs, ... }: {
  users.users.$USER = {
    isNormalUser = true;
    description = "$USER";
    extraGroups = [ "$GROUPS" ];
    shell = pkgs.zsh;
    packages = with pkgs; [
      atuin
      bat
      chezmoi
      fzf
      fzf-zsh
      lazygit
      starship
      statix
      tree
      yazi
      zoxide
    ];
  };
}
