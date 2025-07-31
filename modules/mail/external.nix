{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.puyonexus.mail.externalMta;
in
{
  options = {
    puyonexus.mail = {
      externalMta = {
        enable = lib.mkEnableOption "external MTA";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    sops = {
      secrets =
        let
          grafanaOwnership = {
            owner = config.users.users.grafana.name;
          };
        in
        {
          "smtp/host" = { };
          "smtp/port" = { };
          "smtp/username" = { };
          "smtp/password" = { };
          "grafana/smtp/host" = {
            key = "smtp/host";
          }
          // grafanaOwnership;
          "grafana/smtp/port" = {
            key = "smtp/port";
          }
          // grafanaOwnership;
          "grafana/smtp/username" = {
            key = "smtp/username";
          }
          // grafanaOwnership;
          "grafana/smtp/password" = {
            key = "smtp/password";
          }
          // grafanaOwnership;
        };
      templates = {
        "msmtp-config" = {
          content = ''
            account outgoing
            auth on
            tls on
            host ${config.sops.placeholder."smtp/host"}
            port ${toString config.sops.placeholder."smtp/port"}
            from noreply@${config.puyonexus.mail.domain}
            user ${config.sops.placeholder."smtp/username"}
            password ${config.sops.placeholder."smtp/password"}
            account default: outgoing
          '';
        };
      };
    };

    # Sendmail to external MTA
    environment.systemPackages = [ pkgs.msmtp ];
    environment.etc."msmtprc" = lib.mkForce { source = config.sops.templates."msmtp-config".path; };
    services.mail.sendmailSetuidWrapper = {
      program = "sendmail";
      source = "${pkgs.msmtp}/bin/sendmail";
      setuid = false;
      setgid = false;
      owner = "root";
      group = "root";
    };

    # External MTA settings for Grafana
    services.grafana.settings.smtp =
      let
        hostPath = config.sops.secrets."grafana/smtp/host".path;
        portPath = config.sops.secrets."grafana/smtp/port".path;
        usernamePath = config.sops.secrets."grafana/smtp/username".path;
        passwordPath = config.sops.secrets."grafana/smtp/password".path;
      in
      {
        enabled = true;
        host = "$__file{${hostPath}}:$__file{${portPath}}";
        user = "$__file{${usernamePath}}";
        password = "$__file{${passwordPath}}";
      };

    # Puyo Nexus MTA settings
    puyonexus = {
      wiki.smtp = {
        host = config.sops.placeholder."smtp/host";
        port = config.sops.placeholder."smtp/port";
        username = config.sops.placeholder."smtp/username";
        password = config.sops.placeholder."smtp/password";
      };
    };
  };
}
