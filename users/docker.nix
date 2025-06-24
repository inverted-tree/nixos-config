{ config, pkgs, ... }:
{
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
}
