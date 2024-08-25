{ config, lib, ... }:
let
  cfg = config.puyonexus.grafana;
  rootDomain = config.puyonexus.domain.root;
in
{
  options = {
    puyonexus.grafana = {
      enable = lib.mkEnableOption "the observability stack";
      domain = lib.mkOption {
        type = lib.types.str;
        default = "grafana.${rootDomain}";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.grafana = {
      enable = true;
      settings = {
        server = {
          protocol = "http";
          http_addr = "127.0.0.1";
          http_port = 3010;
          root_url = "https://${cfg.domain}";
        };
        analytics.reporting_enabled = false;
        smtp = {
          enabled = true;
          from_name = "Puyo Nexus Grafana";
          from_address = "grafana@${config.puyonexus.domain.root}";
        };
      };

      provision = {
        enable = true;
        datasources.settings.datasources = [
          {
            name = "Prometheus";
            type = "prometheus";
            access = "proxy";
            url = "http://127.0.0.1:${toString config.services.prometheus.port}";
            uid = "prometheusDataSource";
          }
          {
            name = "Loki";
            type = "loki";
            access = "proxy";
            url = "http://127.0.0.1:${toString config.services.loki.configuration.server.http_listen_port}";
            uid = "lokiDataSource";
          }
        ];
        dashboards.settings = {
          apiVersion = 1;
          providers = [
            {
              name = "default";
              options.path = ./dashboards;
            }
          ];
        };
        alerting.rules.path = ./alerting-rules;
        alerting.contactPoints.path = ./contact-points;
        alerting.policies.path = ./notification-policies;
      };
    };

    # NGINX proxy configuration
    security.acme.certs.${cfg.domain} = lib.mkIf config.puyonexus.acme.enable {
      group = config.services.nginx.group;
    };
    services.nginx = {
      virtualHosts.${cfg.domain} = {
        useACMEHost = lib.mkIf config.puyonexus.acme.enable cfg.domain;
        forceSSL = config.puyonexus.acme.enable;
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString config.services.grafana.settings.server.http_port}";
          proxyWebsockets = true;
          basicAuthFile = config.puyonexus.users.basicAuthFile;
          extraConfig = ''
            proxy_set_header Host $host;
          '';
        };
      };
    };
  };
}
