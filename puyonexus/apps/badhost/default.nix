{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.puyonexus.badhost;
in
{
  options = {
    puyonexus.badhost = {
      enable = lib.mkEnableOption "Puyo Nexus Bad Host Handler";
    };
  };

  config = lib.mkIf cfg.enable {
    services.nginx = {
      enable = true;
      virtualHosts."badhost" = {
        default = true;
        # Only support SSL if ACME is enabled
        addSSL = config.puyonexus.acme.enable;
        # We'll use the root domain cert here, it will fail anyways.
        useACMEHost = lib.mkIf config.puyonexus.acme.enable config.puyonexus.domain.root;
        locations."/" = {
          alias = ./.;
          tryFiles = "/index.html =404";
        };
      };
    };
  };
}
