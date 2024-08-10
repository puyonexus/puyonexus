{ config, lib, ... }:
let
  cfg = config.puyonexus.observability;
in
{
  options = {
    puyonexus.observability = {
      enableMonolith = lib.mkEnableOption "monolithic observability stack";
    };
  };

  config = lib.mkIf cfg.enableMonolith {
    puyonexus = {
      prometheusExporters.enable = true;
      prometheus = {
        enable = true;
        targets = [
          "127.0.0.1:${toString config.puyonexus.prometheusExporters.nodeExporterPort}"
          "127.0.0.1:${toString config.puyonexus.prometheusExporters.nginxExporterPort}"
        ];
      };
      loki = {
        enable = true;
      };
      promtail = {
        enable = true;
        lokiUrl = "http://127.0.0.1:${toString config.puyonexus.loki.listenPort}";
      };
    };
  };
}
