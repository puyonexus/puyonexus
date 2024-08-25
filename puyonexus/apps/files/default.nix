{ config, lib, ... }:
let
  cfg = config.puyonexus.files;
in
{
  options = {
    puyonexus.files = {
      enable = lib.mkEnableOption "Puyo Nexus Files Archive";
      domain = lib.mkOption {
        type = lib.types.str;
        default = config.puyonexus.domain.root;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.nginx = {
      enable = true;
      virtualHosts.${cfg.domain} = {
        locations = {
          "/files/" = {
            alias = "/data/files/";
            extraConfig = ''
              autoindex on;
            '';
          };
          "= /files".return = "301 /files/";
        };
      };
    };
  };
}
