{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.puyonexus.forum;
  mkConfig = import ./make-config.nix;
in
{
  options = {
    puyonexus.forum = {
      enable = lib.mkEnableOption "Puyo Nexus Forum";
      domain = lib.mkOption {
        type = lib.types.str;
        default = config.puyonexus.domain.root;
      };
      path = lib.mkOption {
        type = lib.types.str;
        default = "/forum";
      };
      urlPrefix = lib.mkOption {
        type = lib.types.str;
        default = "${config.puyonexus.nginx.urlPrefix}${cfg.path}";
      };
      mysql = {
        host = lib.mkOption { type = lib.types.str; };
        port = lib.mkOption { type = lib.types.int; };
        username = lib.mkOption {
          type = lib.types.str;
          default = config.sops.placeholder."mysql/username";
        };
        password = lib.mkOption {
          type = lib.types.str;
          default = config.sops.placeholder."mysql/password";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    puyonexus.php.enable = true;

    services.nginx = {
      enable = true;
      virtualHosts.${cfg.domain} = {
        locations = {
          "${cfg.path}/" = {
            alias = "${pkgs.puyonexusPackages.forum}/share/php/puyonexus-forum/";
            extraConfig = ''
              index index.php;
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
          "= ${cfg.path}".return = "301 ${cfg.urlPrefix}/";
        };
      };
    };

    environment.systemPackages = [
      pkgs.puyonexusPackages.forum
      pkgs.updateForum
    ];

    sops.templates."puyonexus-forum-config.php" = {
      content = mkConfig {
        mysqlHost = cfg.mysql.host;
        mysqlPort = cfg.mysql.port;
        mysqlUsername = cfg.mysql.username;
        mysqlPassword = cfg.mysql.password;
      };
      owner = config.users.users.puyonexus.name;
    };

    environment.variables = {
      PUYONEXUS_FORUM_CONFIG_PATH = config.sops.templates."puyonexus-forum-config.php".path;
    };

    services.phpfpm.pools.www.phpEnv = {
      inherit (config.environment.variables) PUYONEXUS_FORUM_CONFIG_PATH;
    };
  };
}
