# ██████╗  ██████╗  ██████╗██╗  ██╗███████╗██████╗     ██╗   ██╗███████╗███████╗██████╗
# ██╔══██╗██╔═══██╗██╔════╝██║ ██╔╝██╔════╝██╔══██╗    ██║   ██║██╔════╝██╔════╝██╔══██╗
# ██║  ██║██║   ██║██║     █████╔╝ █████╗  ██████╔╝    ██║   ██║███████╗█████╗  ██████╔╝
# ██║  ██║██║   ██║██║     ██╔═██╗ ██╔══╝  ██╔══██╗    ██║   ██║╚════██║██╔══╝  ██╔══██╗
# ██████╔╝╚██████╔╝╚██████╗██║  ██╗███████╗██║  ██║    ╚██████╔╝███████║███████╗██║  ██║
# ╚═════╝  ╚═════╝  ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝     ╚═════╝ ╚══════╝╚══════╝╚═╝  ╚═╝
# ══════════════════════════════════════════════════════════════════════════════════════
# Defines a standard user that owns all docker containers and sets the
#  virtualisation backend to be docker. Container modules need to be explicitly
#  defined to use this user as their owner.

{ config, pkgs, ... }: {
  users = {
    users.docker = {
      description = "This user runs the Docker containers.";
      isSystemUser = true;
      home = "/var/lib/docker-run";
      createHome = true;
      group = "docker";
      uid = 990;
    };
  };

  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
  };
  virtualisation.oci-containers.backend = "docker";
}
