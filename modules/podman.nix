# .          _
#  ___ ___ _| |_____  __ ___
# | . | . | . |     ||. |   |
# |  _|___|___|_|_|_|___|_|_|
# |_|
# ──────────────────────────────────────────────────────────────────────────────
# Use Podman as the OCI container backend for running root- and deamonless
#  container services. All containers are managed with quadlet-nix.

{ pkgs, ... }:
{
  users.groups.podman = {
    name = "podman";
  };

  virtualisation = {
    podman = {
      enable = true;

      autoPrune.enable = true;
      autoPrune.flags = [
        "--all"
        "--force"
      ];

      defaultNetwork.settings = {
        dns_enabled = true; # Required for container networking to use names.
      };
      extraPackages = [ pkgs.zfs ];
    };

    quadlet = {
      enable = true;
      autoUpdate.enable = true;
    };
  };

  environment.systemPackages = with pkgs; [
    podman
    podman-tui
    slirp4netns
    home-manager
  ];

  boot.kernel.sysctl."net.ipv4.ip_unprivileged_port_start" = 53; # Allow non-root containers to access lower port numbers
}
