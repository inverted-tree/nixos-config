# ███╗   ███╗██╗███╗   ██╗███████╗ ██████╗██████╗  █████╗ ███████╗████████╗
# ████╗ ████║██║████╗  ██║██╔════╝██╔════╝██╔══██╗██╔══██╗██╔════╝╚══██╔══╝
# ██╔████╔██║██║██╔██╗ ██║█████╗  ██║     ██████╔╝███████║█████╗     ██║
# ██║╚██╔╝██║██║██║╚██╗██║██╔══╝  ██║     ██╔══██╗██╔══██║██╔══╝     ██║
# ██║ ╚═╝ ██║██║██║ ╚████║███████╗╚██████╗██║  ██║██║  ██║██║        ██║
# ╚═╝     ╚═╝╚═╝╚═╝  ╚═══╝╚══════╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝        ╚═╝
# ═════════════════════════════════════════════════════════════════════════
# A simple minecraft server module for hosting a local network server.

{
  pkgs,
  lib,
  config,
  ...
}@args:
let
  inherit (args) inputs;
  nmx = inputs.nix-minecraft;

  serverPack = pkgs.fetchzip {
    url = "https://mediafilez.forgecdn.net/files/6974/725/Prominence%20II%20Hasturian%20Era-v3.9.0.zip";
    sha256 = "sha256-qa6Ma1LC/BnGF9yCSMb0hit3Sgx4bcgt7UAUo9aTeKM=";
    stripRoot = false;
  };
  maybeCollect =
    dir:
    if builtins.pathExists "${serverPack}/${dir}" then nmx.lib.collectFilesAt serverPack dir else { };
in
{
  imports = [ nmx.nixosModules.minecraft-servers ];

  nixpkgs.overlays = [ nmx.overlay ];

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ "minecraft-server" ];

  services.minecraft-servers = {
    enable = true;
    eula = true;
    openFirewall = true;

    servers = {
      rpg-server = {
        enable = true;
        autoStart = true;
        package = pkgs.fabricServers.fabric-1_20_1;

        jvmOpts = "-Xms8G -Xmx8G -XX:+UseG1GC -XX:MaxGCPauseMillis=100 -XX:+ParallelRefProcEnabled";

        serverProperties = {
          motd = "Lukas' Epic Minecraft Server!";
        };

        files =
          maybeCollect "mods"
          // maybeCollect "overrides/mods"
          // maybeCollect "config"
          // maybeCollect "defaultconfigs"
          // maybeCollect "kubejs"
          // maybeCollect "scripts"
          // maybeCollect "config/ftbquests"
          // maybeCollect "overrides/config" # some CF packs use overrides/
          // maybeCollect "overrides/defaultconfigs";
      };
    };
  };
}
