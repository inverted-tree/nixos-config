# ██████╗  █████╗ ██████╗ ███████╗██████╗ ██╗     ███████╗███████╗███████╗    ███╗   ██╗ ██████╗ ██╗  ██╗
# ██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗██║     ██╔════╝██╔════╝██╔════╝    ████╗  ██║██╔════╝ ╚██╗██╔╝
# ██████╔╝███████║██████╔╝█████╗  ██████╔╝██║     █████╗  ███████╗███████╗    ██╔██╗ ██║██║  ███╗ ╚███╔╝ 
# ██╔═══╝ ██╔══██║██╔═══╝ ██╔══╝  ██╔══██╗██║     ██╔══╝  ╚════██║╚════██║    ██║╚██╗██║██║   ██║ ██╔██╗ 
# ██║     ██║  ██║██║     ███████╗██║  ██║███████╗███████╗███████║███████║    ██║ ╚████║╚██████╔╝██╔╝ ██╗
# ╚═╝     ╚═╝  ╚═╝╚═╝     ╚══════╝╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝╚══════╝    ╚═╝  ╚═══╝ ╚═════╝ ╚═╝  ╚═╝
# ════════════════════════════════════════════════════════════════════════════════════════════
# This module was auto-generated using compose2nix v0.3.1 and then edited
#  by hand. Paperless-ngx is a document management system. For more information
#  look at: https://docs.paperless-ngx.com/setup.

{ pkgs, lib, config, ... }@args:
let inherit (args) inputs;
in {
  imports = [
    # The docker user:
    ../../users/docker.nix
    # Any other modules:
    inputs.sops-nix.nixosModules.sops
  ];

  sops = {
    secrets.paperless-ngx-env = {
      sopsFile = ../../secrets/paperless-ngx.env.enc;
      format = "dotenv";
    };
  };

  # Create persistent directory for the redis data
  systemd.tmpfiles.rules = [
    "d /srv/paperless-ngx/redis/data 0750 docker docker -"
    "d /srv/paperless-ngx/postgres/data 0750 docker docker -"
    "d /srv/paperless-ngx/webserver/consume 0750 docker docker -"
    "d /srv/paperless-ngx/webserver/export 0750 docker docker -"
    "d /srv/paperless-ngx/webserver/data 0750 docker docker -"
    "d /srv/paperless-ngx/webserver/media 0750 docker docker -"
  ];

  # Containers
  virtualisation.oci-containers.containers."paperless-ngx-broker" = {
    image = "docker.io/library/redis:8";
    volumes = [ "srv/paperless-ngx/redis/data:/data:rw" ];
    log-driver = "journald";
    extraOptions =
      [ "--network-alias=broker" "--network=paperless-ngx_default" ];
  };
  systemd.services."docker-paperless-ngx-broker" = {
    serviceConfig = {
      Restart = lib.mkOverride 90 "always";
      RestartMaxDelaySec = lib.mkOverride 90 "1m";
      RestartSec = lib.mkOverride 90 "100ms";
      RestartSteps = lib.mkOverride 90 9;
    };
    after = [
      "docker-network-paperless-ngx_default.service"
      "docker-volume-paperless-ngx_redisdata.service"
    ];
    requires = [
      "docker-network-paperless-ngx_default.service"
      "docker-volume-paperless-ngx_redisdata.service"
    ];
    partOf = [ "docker-compose-paperless-ngx-root.target" ];
    wantedBy = [ "docker-compose-paperless-ngx-root.target" ];
  };

  virtualisation.oci-containers.containers."paperless-ngx-db" = {
    image = "docker.io/library/postgres:17";

    environmentFiles = [ config.sops.secrets.paperless-ngx-env.path ];
    # environment = {
    #   "POSTGRES_DB" = "paperless";
    #   "POSTGRES_PASSWORD" = "paperless";
    #   "POSTGRES_USER" = "paperless";
    # };
    volumes =
      [ "/srv/paperless-ngx/postgres/data:/var/lib/postgresql/data:rw" ];
    log-driver = "journald";
    extraOptions = [ "--network-alias=db" "--network=paperless-ngx_default" ];
  };
  systemd.services."docker-paperless-ngx-db" = {
    serviceConfig = {
      Restart = lib.mkOverride 90 "always";
      RestartMaxDelaySec = lib.mkOverride 90 "1m";
      RestartSec = lib.mkOverride 90 "100ms";
      RestartSteps = lib.mkOverride 90 9;
    };
    after = [
      "docker-network-paperless-ngx_default.service"
      "docker-volume-paperless-ngx_pgdata.service"
    ];
    requires = [
      "docker-network-paperless-ngx_default.service"
      "docker-volume-paperless-ngx_pgdata.service"
    ];
    partOf = [ "docker-compose-paperless-ngx-root.target" ];
    wantedBy = [ "docker-compose-paperless-ngx-root.target" ];
  };

  virtualisation.oci-containers.containers."paperless-ngx-webserver" = {
    image = "ghcr.io/paperless-ngx/paperless-ngx:latest";
    environment = {
      "PAPERLESS_DBHOST" = "db";
      "PAPERLESS_REDIS" = "redis://broker:6379";
    };
    volumes = [
      "/srv/paperless-ngx/webserver/consume:/usr/src/paperless/consume:rw"
      "/srv/paperless-ngx/webserver/export:/usr/src/paperless/export:rw"
      "/srv/paperless-ngx/webserver:/usr/src/paperless/data:rw"
      "/srv/paperless-ngx/webserver:/usr/src/paperless/media:rw"
    ];
    ports = [ "8000:8000/tcp" ];
    dependsOn = [ "paperless-ngx-broker" "paperless-ngx-db" ];
    log-driver = "journald";
    extraOptions =
      [ "--network-alias=webserver" "--network=paperless-ngx_default" ];
  };
  systemd.services."docker-paperless-ngx-webserver" = {
    serviceConfig = {
      Restart = lib.mkOverride 90 "always";
      RestartMaxDelaySec = lib.mkOverride 90 "1m";
      RestartSec = lib.mkOverride 90 "100ms";
      RestartSteps = lib.mkOverride 90 9;
    };
    after = [
      "docker-network-paperless-ngx_default.service"
      "docker-volume-paperless-ngx_data.service"
      "docker-volume-paperless-ngx_media.service"
    ];
    requires = [
      "docker-network-paperless-ngx_default.service"
      "docker-volume-paperless-ngx_data.service"
      "docker-volume-paperless-ngx_media.service"
    ];
    partOf = [ "docker-compose-paperless-ngx-root.target" ];
    wantedBy = [ "docker-compose-paperless-ngx-root.target" ];
  };

  # Networks
  systemd.services."docker-network-paperless-ngx_default" = {
    path = [ pkgs.docker ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStop = "docker network rm -f paperless-ngx_default";
    };
    script = ''
      docker network inspect paperless-ngx_default || docker network create paperless-ngx_default
    '';
    partOf = [ "docker-compose-paperless-ngx-root.target" ];
    wantedBy = [ "docker-compose-paperless-ngx-root.target" ];
  };

  # Volumes
  systemd.services."docker-volume-paperless-ngx_data" = {
    path = [ pkgs.docker ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      docker volume inspect paperless-ngx_data || docker volume create paperless-ngx_data
    '';
    partOf = [ "docker-compose-paperless-ngx-root.target" ];
    wantedBy = [ "docker-compose-paperless-ngx-root.target" ];
  };
  systemd.services."docker-volume-paperless-ngx_media" = {
    path = [ pkgs.docker ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      docker volume inspect paperless-ngx_media || docker volume create paperless-ngx_media
    '';
    partOf = [ "docker-compose-paperless-ngx-root.target" ];
    wantedBy = [ "docker-compose-paperless-ngx-root.target" ];
  };
  systemd.services."docker-volume-paperless-ngx_pgdata" = {
    path = [ pkgs.docker ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      docker volume inspect paperless-ngx_pgdata || docker volume create paperless-ngx_pgdata
    '';
    partOf = [ "docker-compose-paperless-ngx-root.target" ];
    wantedBy = [ "docker-compose-paperless-ngx-root.target" ];
  };
  systemd.services."docker-volume-paperless-ngx_redisdata" = {
    path = [ pkgs.docker ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      docker volume inspect paperless-ngx_redisdata || docker volume create paperless-ngx_redisdata
    '';
    partOf = [ "docker-compose-paperless-ngx-root.target" ];
    wantedBy = [ "docker-compose-paperless-ngx-root.target" ];
  };

  networking.firewall.allowedTCPPorts = [ 8000 ];

  # Root service
  # When started, this will automatically create all resources and start
  # the containers. When stopped, this will teardown all resources.
  systemd.targets."docker-compose-paperless-ngx-root" = {
    unitConfig = { Description = "Root target generated by compose2nix."; };
    wantedBy = [ "multi-user.target" ];
  };
}
