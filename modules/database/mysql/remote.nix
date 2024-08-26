{ config, lib, ... }:
let
  cfg = config.puyonexus.mysql.remote;
in
{
  options = {
    puyonexus.mysql.remote = {
      enable = lib.mkEnableOption "Remote MySQL server";
      host = lib.mkOption { type = lib.types.str; };
      port = lib.mkOption { type = lib.types.int; };
    };
  };

  config = lib.mkIf cfg.enable {
    puyonexus.wiki.mysql.server = "${cfg.host}:${toString cfg.port}";
    puyonexus.chainsim.database.dsn = "mysql:host=${cfg.host};port=${toString cfg.port};dbname=puyonexus";
  };
}
