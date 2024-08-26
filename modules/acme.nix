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
    sops.secrets = {
      "digitalocean/authToken" = { };
    };
    security.acme = {
      acceptTerms = true;
      defaults = {
        email = "acme@${config.puyonexus.domain.root}";
        dnsProvider = "digitalocean";
        credentialFiles = {
          "DO_AUTH_TOKEN_FILE" = config.sops.secrets."digitalocean/authToken".path;
        };
      };
    };
  };
}
