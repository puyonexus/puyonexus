{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.puyonexus.mysql.local;
in
{
  options = {
    puyonexus.mysql.local = {
      enable = lib.mkEnableOption "Local MySQL server";
    };
  };

  config = lib.mkIf cfg.enable {
    services.mysql = {
      enable = true;
      package = pkgs.mariadb;
      initialDatabases = [ { name = "puyonexus"; } ];
      ensureUsers = [
        {
          name = "puyonexus";
          ensurePermissions = {
            # See https://phabricator.wikimedia.org/T193552.
            "puyonexus.*" = "ALL PRIVILEGES";
          };
        }
      ];
    };

    puyonexus.wiki.mysql.server = "localhost:/run/mysqld/mysqld.sock";
    puyonexus.chainsim.database.dsn = "mysql:unix_socket=/run/mysqld/mysqld.sock;dbname=puyonexus";
  };
}
