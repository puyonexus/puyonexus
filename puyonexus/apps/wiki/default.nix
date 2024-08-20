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
      domain = lib.mkOption {
        type = lib.types.str;
        default = config.puyonexus.domain.root;
      };
      urlPrefix = lib.mkOption {
        type = lib.types.str;
        default =
          let
            scheme = if config.puyonexus.acme.enable then "https" else "http";
            suffix = if config.puyonexus.acme.enable then "" else ":8080";
          in
          "${scheme}://${cfg.domain}${suffix}";
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
      virtualHosts.${config.puyonexus.domain.root} = {
        locations = {
          "/wiki/".extraConfig = ''
            rewrite ^/wiki/(?<pagename>.*)$ /mediawiki/index.php;
          '';
          "= /wiki".extraConfig = ''
            return 301 /wiki/;
          '';
          "/mediawiki/images/" = {
            alias = withTrailingSlash cfg.imagesDir;
            extraConfig = ''
              add_header X-Content-Type-Options nosniff;
            '';
          };
          "/mediawiki/images/deleted" = {
            extraConfig = ''
              deny all;
            '';
          };
          "/wiki/rest.php/" = {
            # Handling for Mediawiki REST API, see [[mw:API:REST_API]]
            tryFiles = "$uri $uri/ /mediawiki/rest.php?$query_string";
          };
          "/mediawiki/" = {
            alias = "${pkgs.puyonexusWiki}/share/php/puyonexus-wiki/";
            extraConfig = ''
              autoindex on;
              index index.php;
              try_files $uri $uri/ $uri.php;
              location ~ \.php$ {
                try_files $uri =404;
                fastcgi_split_path_info ^(.+\.php)(/.+)$;
                fastcgi_pass unix:${config.services.phpfpm.pools.www.socket};
                fastcgi_index index.php;
                include ${pkgs.nginx.out}/conf/fastcgi_params;
                fastcgi_param SCRIPT_FILENAME $request_filename;
                fastcgi_intercept_errors on;
              }
            '';
          };
        };
      };
    };

    environment.systemPackages = [
      pkgs.puyonexusWiki
      pkgs.initWiki
      pkgs.updateWiki
      pkgs.multiUpdateWiki
    ];

    sops.templates."puyonexus-wiki-localsettings.php" = {
      content = mkLocalSettings {
        server = cfg.urlPrefix;
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
        uploadDir = cfg.imagesDir;
      };
      owner = config.users.users.puyonexus.name;
    };

    environment.variables = {
      PUYONEXUS_WIKI_LOCALSETTINGS_PATH = config.sops.templates."puyonexus-wiki-localsettings.php".path;
    };

    services.phpfpm.pools.www.phpEnv = {
      inherit (config.environment.variables) PUYONEXUS_WIKI_LOCALSETTINGS_PATH;
    };
  };
}
