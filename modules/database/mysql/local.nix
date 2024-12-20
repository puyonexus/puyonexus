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
    # Always restart MySQL aggressively.
    systemd.services.mysql = {
      startLimitIntervalSec = 0;
      unitConfig = {
        Restart = "always";
        RestartSec = 10;
        # MySQL is almost always the wrong OOM target.
        # Force OOM killer to heavily consider other targets.
        OOMScoreAdjust = -800;
      };
    };

    puyonexus.wiki.mysql.server = "localhost:/run/mysqld/mysqld.sock";
    puyonexus.chainsim.database.dsn = "mysql:unix_socket=/run/mysqld/mysqld.sock;dbname=puyonexus";
    puyonexus.forum.mysql.host = "localhost";
    puyonexus.forum.mysql.port = 3306;
  };
}
