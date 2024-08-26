{ config, lib, ... }:
let
  cfg = config.puyonexus.prometheus;
in
{
  options = {
    puyonexus.prometheus = {
      enable = lib.mkEnableOption "Prometheus";
      listenPort = lib.mkOption {
        type = lib.types.int;
        default = 3020;
      };
      targets = lib.mkOption { type = lib.types.listOf lib.types.str; };
    };
  };

  config = lib.mkIf cfg.enable {
    services.prometheus = {
      enable = true;
      port = cfg.listenPort;
      scrapeConfigs = [
        {
          job_name = "nodes";
          static_configs = [ { targets = cfg.targets; } ];
        }
      ];
    };
  };
}
