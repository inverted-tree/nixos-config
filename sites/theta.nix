# .    _ _          _   _       _
#  ___|_| |_ ___   | |_| |_ ___| |_  __
# |_ -| |  _| -_|  |  _|   | -_|  _||. |
# |___|_| | |___|  | | |_|_|___| | |___|
# .     |__|       |__|        |__|
# ──────────────────────────────────────────────────────────────────────────────
# Deployment site theta. This nix expression sets all site-related options.

{ ... }:
{
  time.timeZone = "Europe/Berlin";

  networking = {
    defaultGateway = {
      address = "10.0.0.1";
    };
  };
}
