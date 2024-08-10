{ config, lib, ... }:
let
  cfg = config.puyonexus.prometheusExporters;
in
{
  options = {
    puyonexus.prometheusExporters = {
      enable = lib.mkEnableOption "metrics exporters";
      listenAddress = lib.mkOption {
        type = lib.types.str;
        default = "127.0.0.1";
      };
      nodeExporterPort = lib.mkOption {
        type = lib.types.int;
        default = 3021;
      };
      nginxExporterPort = lib.mkOption {
        type = lib.types.int;
        default = 3022;
      };

      # TODO: use unix domain socket for NGINX stub
      nginxStubPort = lib.mkOption {
        type = lib.types.int;
        default = 3040;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.nginx = {
      virtualHosts."localhost" = {
        listen = lib.singleton {
          addr = "localhost";
          port = cfg.nginxStubPort;
        };
        locations."/_status".extraConfig = ''
          stub_status;
        '';
      };
    };

    services.prometheus = {
      exporters = {
        node = {
          enable = true;
          enabledCollectors = [ "systemd" ];
          listenAddress = cfg.listenAddress;
          port = cfg.nodeExporterPort;
        };
        nginx = lib.mkIf config.services.nginx.enable {
          enable = true;
          listenAddress = cfg.listenAddress;
          port = cfg.nginxExporterPort;
          scrapeUri = "http://localhost:${toString cfg.nginxStubPort}/_status";
        };
      };
    };
  };
}
