{ inputs, ... }:
{
  imports = [
    inputs.home-manager.nixosModules.home-manager

    ./atuin
    ./freshrss
    ./glance
    ./grafana
    # ./homeassistant/default.nix
    ./pihole
    # ./plex/default.nix
    ./prometheus
    ./stump
  ];
}
