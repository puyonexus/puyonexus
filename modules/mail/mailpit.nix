{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.puyonexus.mail.mailpit;
in
{
  options = {
    puyonexus.mail = {
      mailpit = {
        enable = lib.mkEnableOption "mailpit MTA";
        httpPort = lib.mkOption {
          type = lib.types.int;
          default = 8025;
        };
        domain = lib.mkOption {
          type = lib.types.str;
          default = "mailpit.${config.puyonexus.domain.root}";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Mailpit service
    systemd.services.mailpit = {
      description = "Mock e-mail server";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      restartIfChanged = true;
      serviceConfig = {
        ProtectSystem = "full";
        ProtectHome = "read-only";
        ProtectHostname = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectKernelLogs = true;
        ProtectControlGroups = true;
        AmbientCapabilities = "CAP_NET_BIND_SERVICE";
        Type = "exec";
        ExecStart = ''${pkgs.mailpit.out}/bin/mailpit --listen "[::]:${toString cfg.httpPort}"'';
      };
    };

    # Allow mailpit access externally
    security.acme.certs.${cfg.domain} = lib.mkIf config.puyonexus.acme.enable {
      group = config.services.nginx.group;
    };
    services.nginx = {
      virtualHosts.${cfg.domain} = {
        useACMEHost = lib.mkIf config.puyonexus.acme.enable cfg.domain;
        forceSSL = config.puyonexus.acme.enable;
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString cfg.httpPort}";
          proxyWebsockets = true;
          basicAuthFile = config.puyonexus.users.basicAuthFile;
          extraConfig = ''
            proxy_set_header Host $host;
          '';
        };
      };
    };

    # Sendmail to mailpit
    environment.systemPackages = [ pkgs.msmtp ];
    environment.etc."msmtprc" = lib.mkForce {
      text = ''
        account outgoing
        auth on
        tls on
        host 127.0.0.1
        port 1025
        from noreply@${cfg.domain}
        user test
        password test
        account default: outgoing
      '';
      mode = "0600";
    };

    services.mail.sendmailSetuidWrapper = {
      program = "sendmail";
      source = "${pkgs.msmtp}/bin/sendmail";
      setuid = false;
      setgid = false;
      owner = "root";
      group = "root";
    };

    # Mailpit settings for Grafana
    services.grafana.settings.smtp = {
      enabled = true;
      host = "127.0.0.1:1025";
      user = "test";
      password = "test";
    };

    # Mailpit settings for Puyo Nexus Wiki
    puyonexus.wiki.smtp = {
      host = "127.0.0.1";
      port = "1025";
      username = "test";
      password = "test";
    };
  };
}
