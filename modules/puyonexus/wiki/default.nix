{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.puyonexus.wiki;
  mkLocalSettings = import ./make-local-settings.nix;
  withTrailingSlash = str: if lib.hasSuffix "/" str then str else "${str}/";
in
{
  options = {
    puyonexus.wiki = {
      enable = lib.mkEnableOption "Puyo Nexus Wiki";
      enableEmail = lib.mkEnableOption "Puyo Nexus Wiki E-mail";
      domain = lib.mkOption {
        type = lib.types.str;
        default = config.puyonexus.nginx.domain;
      };
      path = lib.mkOption {
        type = lib.types.str;
        default = "/wiki";
      };
      scriptPath = lib.mkOption {
        type = lib.types.str;
        default = "/mediawiki";
      };
      serverUrlPrefix = lib.mkOption {
        type = lib.types.str;
        default = config.puyonexus.nginx.urlPrefix;
      };
      urlPrefix = lib.mkOption {
        type = lib.types.str;
        default = "${cfg.serverUrlPrefix}${cfg.path}";
      };
      secretKey = lib.mkOption {
        type = lib.types.str;
        default = config.sops.placeholder."wiki/secretKey";
      };
      upgradeKey = lib.mkOption {
        type = lib.types.str;
        default = config.sops.placeholder."wiki/upgradeKey";
      };
      smtp = {
        host = lib.mkOption { type = lib.types.str; };
        port = lib.mkOption { type = lib.types.str; };
        username = lib.mkOption { type = lib.types.str; };
        password = lib.mkOption { type = lib.types.str; };
      };
      mysql = {
        server = lib.mkOption { type = lib.types.str; };
        username = lib.mkOption {
          type = lib.types.str;
          default = config.sops.placeholder."mysql/username";
        };
        password = lib.mkOption {
          type = lib.types.str;
          default = config.sops.placeholder."mysql/password";
        };
      };
      imagesDir = lib.mkOption {
        type = lib.types.path;
        default = "/data/wiki-images/";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    puyonexus.php.enable = true;

    sops.secrets = {
      "wiki/secretKey" = { };
      "wiki/upgradeKey" = { };
      "mysql/username" = { };
      "mysql/password" = { };
    };

    services.nginx = {
      enable = true;
      virtualHosts.${cfg.domain} = {
        locations = {
          "${cfg.path}/".extraConfig = ''
            rewrite ^${cfg.path}/(?<pagename>.*)$ ${cfg.scriptPath}/index.php;
          '';
          "= ${cfg.path}".return = "301 ${cfg.urlPrefix}/";
          "${cfg.scriptPath}/images/" = {
            alias = withTrailingSlash cfg.imagesDir;
            extraConfig = ''
              add_header X-Content-Type-Options nosniff;
            '';
          };
          "${cfg.scriptPath}/images/deleted" = {
            extraConfig = ''
              deny all;
            '';
          };
          "${cfg.path}/rest.php/" = {
            # Handling for Mediawiki REST API, see [[mw:API:REST_API]]
            tryFiles = "$uri $uri/ ${cfg.scriptPath}/rest.php?$query_string";
          };
          "${cfg.scriptPath}/" = {
            alias = "${pkgs.puyonexusPackages.wiki}/share/php/puyonexus-wiki/";
            extraConfig = ''
              index index.php;
              try_files $uri $uri/ $uri.php;
              location ~ \.php$ {
                try_files $uri =404;
                fastcgi_split_path_info ^(.+\.php)(/.+)$;
                fastcgi_pass unix:${config.services.phpfpm.pools.www.socket};
                fastcgi_index index.php;
                include ${pkgs.nginx.out}/conf/fastcgi_params;
                fastcgi_param SCRIPT_FILENAME $request_filename;
              }
            '';
          };
        };
      };
    };

    environment.systemPackages = [
      pkgs.puyonexusPackages.wiki
      pkgs.initWiki
      pkgs.updateWiki
    ];

    services.redis.servers.wiki = {
      enable = true;
      user = config.users.users.puyonexus.name;
      settings = {
        maxmemory = "512mb";
        maxmemory-policy = "volatile-lru";
      };
    };

    systemd.services.redis-wiki.serviceConfig = {
      Restart = "always";
      RestartSec = 1;
      RestartSteps = 5;
      RestartMaxDelaySec = 10;
    };

    sops.templates."puyonexus-wiki-localsettings.php" = {
      content = mkLocalSettings {
        inherit lib;
        server = cfg.serverUrlPrefix;
        path = cfg.path;
        scriptPath = cfg.scriptPath;
        domain = cfg.domain;
        secretKey = cfg.secretKey;
        upgradeKey = cfg.upgradeKey;
        mysqlServer = cfg.mysql.server;
        mysqlUsername = cfg.mysql.username;
        mysqlPassword = cfg.mysql.password;
        smtpHost = cfg.smtp.host;
        smtpPort = cfg.smtp.port;
        smtpUsername = cfg.smtp.username;
        smtpPassword = cfg.smtp.password;
        redisSocket = config.services.redis.servers.wiki.unixSocket;
        uploadDir = cfg.imagesDir;
        enableEmail = cfg.enableEmail;
      };
      owner = config.users.users.puyonexus.name;
    };

    environment.variables = {
      PUYONEXUS_WIKI_LOCALSETTINGS_PATH = config.sops.templates."puyonexus-wiki-localsettings.php".path;
    };

    services.phpfpm.pools.www.phpEnv = {
      inherit (config.environment.variables) PUYONEXUS_WIKI_LOCALSETTINGS_PATH;
    };

    # TODO: Replace with Redis-based job runner.
    systemd.services.mwjobrunner = {
      description = "MediaWiki job runner";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      restartIfChanged = true;
      environment = {
        inherit (config.environment.variables) PUYONEXUS_WIKI_LOCALSETTINGS_PATH;
      };
      serviceConfig = {
        ProtectSystem = "full";
        User = config.users.users.puyonexus.name;
        Nice = 20;
        OOMScoreAdjust = 200;
        StandardOutput = "journal";
        Restart = "always";
        RestartSec = "1min";
        Type = "exec";
        ExecStart = ''${
          pkgs.writeShellApplication {
            name = "mwjobrunner";
            runtimeInputs = [ config.puyonexus.php.package ];
            text = ''
              cd ${pkgs.puyonexusPackages.wiki}/share/php/puyonexus-wiki
              while true; do
                echo "[mwjobrunner]: Running jobs."
                php -d memory_limit=512M ${pkgs.puyonexusPackages.wiki}/share/php/puyonexus-wiki/maintenance/run.php runJobs --wait --maxjobs=5 || echo "Ignoring PHP crash."
                echo "[mwjobrunner]: Done, sleeping."
                sleep 1
              done
            '';
          }
        }/bin/mwjobrunner'';
      };
    };
  };
}
