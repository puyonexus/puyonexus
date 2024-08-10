{ config, lib, ... }:
let
  cfg = config.puyonexus.acme;
in
{
  options = {
    puyonexus.acme = {
      enable = lib.mkEnableOption "TLS certificate acquisition via ACME";
    };
  };

  config = lib.mkIf cfg.enable {
    security.acme = {
      acceptTerms = true;
      defaults = {
        email = "acme@${config.puyonexus.domain.root}";
      };
    };
  };
}
