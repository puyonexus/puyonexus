{
  lib,
  config,
  pkgs,
  ...
}:
{
  imports = [
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
    services.nginx = {
      enable = true;
      virtualHosts.${config.puyonexus.domain.root} = {
        enableACME = config.puyonexus.acme.enable;
        forceSSL = config.puyonexus.acme.enable;
      };
    };
    # TODO
    networking.firewall.allowedTCPPorts = [ 80 ];
  };
}
