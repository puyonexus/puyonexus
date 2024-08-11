{ config, lib, ... }:
let
  cfg = config.puyonexus.backup;
in
{
  options = {
    puyonexus.backup = {
      enable = lib.mkEnableOption "backups using restic";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets = {
      "backup/repository" = { };
      "backup/environment" = { };
      "backup/password" = { };
    };
    services.restic.backups.main = {
      initialize = true;
      paths = [ "/var/backup" ];
      repositoryFile = config.sops.secrets."backup/repository".path;
      passwordFile = config.sops.secrets."backup/password".path;
      environmentFile = config.sops.secrets."backup/environment".path;
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
      };
      pruneOpts = [
        "--keep-daily 5"
        "--keep-monthly 10"
        "--keep-yearly 20"
      ];
    };
  };
}
