{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.puyonexus.nginx;
in
{
  options = {
    puyonexus.nginx = {
      enable = lib.mkEnableOption "Puyo Nexus Nginx setup";
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.nginx;
      };
      httpPort = lib.mkOption {
        type = lib.types.int;
        default = 80;
      };
      httpsPort = lib.mkOption {
        type = lib.types.int;
        default = 443;
      };
      useAcme = lib.mkOption {
        type = lib.types.bool;
        default = config.puyonexus.acme.enable;
      };
      useHttps = lib.mkOption {
        type = lib.types.bool;
        default = cfg.useAcme;
      };
      domain = lib.mkOption {
        type = lib.types.str;
        default = config.puyonexus.domain.root;
      };
      urlScheme = lib.mkOption {
        type = lib.types.str;
        default = if cfg.useHttps then "https" else "http";
      };
      urlPortSuffix = lib.mkOption {
        type = lib.types.str;
        default =
          if cfg.useHttps then
            (if cfg.httpsPort != 443 then ":${toString cfg.httpsPort}" else "")
          else
            (if cfg.httpPort != 443 then ":${toString cfg.httpPort}" else "");
      };
      urlPrefix = lib.mkOption {
        type = lib.types.str;
        default = "${cfg.urlScheme}://${cfg.domain}${cfg.urlPortSuffix}";
      };
    };
  };

  config = lib.mkIf config.puyonexus.php.enable {
    security.acme.certs.${cfg.domain} = lib.mkIf config.puyonexus.acme.enable {
      group = config.services.nginx.group;
      extraDomainNames = [ "www.${cfg.domain}" ];
    };
    services.nginx = {
      defaultHTTPListenPort = cfg.httpPort;
      defaultSSLListenPort = cfg.httpsPort;
      enable = true;
      enableReload = true;
      package = config.puyonexus.nginx.package;
      virtualHosts = {
        ${cfg.domain} = {
          useACMEHost = lib.mkIf cfg.useAcme cfg.domain;
          forceSSL = cfg.useHttps;
          # This will be the default host if the badhost handler is disabled.
          default = config.puyonexus.badhost.enable == false;
        };
        "www.${cfg.domain}" = {
          useACMEHost = lib.mkIf cfg.useAcme cfg.domain;
          addSSL = cfg.useHttps;
          locations."/".return = "301 ${cfg.urlPrefix}$request_uri";
        };
      };
    };
    # Always restart Nginx aggressively.
    systemd.services.nginx = {
      startLimitIntervalSec = 0;
      unitConfig = {
        Restart = "always";
        RestartSec = 3;
      };
    };
    networking.firewall.allowedTCPPorts = [
      cfg.httpPort
    ] ++ lib.optionals cfg.useHttps [ cfg.httpsPort ];
  };
}
