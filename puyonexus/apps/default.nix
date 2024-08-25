{
  lib,
  config,
  pkgs,
  ...
}:
{
  imports = [
    ./badhost
    ./chainsim
    ./forum
    ./grafana
    ./home
    ./wiki
  ];

  options = {
    puyonexus.php = {
      enable = lib.mkEnableOption "Puyo Nexus PHP setup";
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.php83;
      };
    };
  };

  config = lib.mkIf config.puyonexus.php.enable {
    environment.systemPackages = [ config.puyonexus.php.package ];
    environment.pathsToLink = [ "/share/php" ];
    services.phpfpm.pools.www = {
      user = config.users.users.puyonexus.name;
      group = config.users.users.puyonexus.group;
      phpPackage = config.puyonexus.php.package;
      settings = {
        "listen.owner" = config.services.nginx.user;
        "pm" = "dynamic";
        "pm.max_children" = 75;
        "pm.start_servers" = 10;
        "pm.min_spare_servers" = 5;
        "pm.max_spare_servers" = 20;
        "pm.max_requests" = 500;
      };
    };
    security.acme.certs.${config.puyonexus.domain.root} = lib.mkIf config.puyonexus.acme.enable {
      group = config.services.nginx.group;
      extraDomainNames = [ "www.${config.puyonexus.domain.root}" ];
    };
    services.nginx = {
      enable = true;
      enableReload = true;
      virtualHosts = {
        ${config.puyonexus.domain.root} = {
          useACMEHost = lib.mkIf config.puyonexus.acme.enable config.puyonexus.domain.root;
          forceSSL = config.puyonexus.acme.enable;
          # This will be the default host if the badhost handler is disabled.
          default = config.puyonexus.badhost.enable == false;
        };
        "www.${config.puyonexus.domain.root}" = {
          useACMEHost = lib.mkIf config.puyonexus.acme.enable config.puyonexus.domain.root;
          forceSSL = config.puyonexus.acme.enable;
          locations."/" = {
            return = "301 http://${config.puyonexus.domain.root}$request_uri";
          };
        };
      };
    };
    networking.firewall.allowedTCPPorts = [
      80
      443
    ];
  };
}
