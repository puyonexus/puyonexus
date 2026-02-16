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
      "cloudflare/zoneApiToken" = { };
      "cloudflare/dnsApiToken" = { };
    };
    security.acme = {
      acceptTerms = true;
      defaults = {
        email = "acme@${config.puyonexus.domain.root}";
        dnsProvider = "cloudflare";
        credentialFiles = {
          "CF_ZONE_API_TOKEN_FILE" = config.sops.secrets."cloudflare/zoneApiToken".path;
          "CF_DNS_API_TOKEN_FILE" = config.sops.secrets."cloudflare/dnsApiToken".path;
        };
      };
    };
  };
}
