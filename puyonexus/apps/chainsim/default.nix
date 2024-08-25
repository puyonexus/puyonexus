{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.puyonexus.chainsim;
  mkLocalSettings = import ./make-local-settings.nix;
in
{
  options = {
    puyonexus.chainsim = {
      enable = lib.mkEnableOption "Puyo Nexus Chainsim";
      domain = lib.mkOption {
        type = lib.types.str;
        default = config.puyonexus.domain.root;
      };
      path = lib.mkOption {
        type = lib.types.str;
        default = "/chainsim";
      };
      urlPrefix = lib.mkOption {
        type = lib.types.str;
        default = "${config.puyonexus.nginx.urlPrefix}${cfg.path}";
      };
      database = {
        dsn = lib.mkOption { type = lib.types.str; };
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

    sops.secrets = {
      "mysql/username" = { };
      "mysql/password" = { };
    };

    services.nginx = {
      enable = true;
      virtualHosts.${cfg.domain} = {
        locations = {
          "${cfg.path}/" = {
            alias = "${pkgs.puyonexusPackages.chainsim}/share/php/puyonexus-chainsim/public/";
            extraConfig = ''
              fastcgi_pass unix:${config.services.phpfpm.pools.www.socket};
              fastcgi_index index.php;
              include ${pkgs.nginx.out}/conf/fastcgi_params;
              fastcgi_param SCRIPT_FILENAME ${pkgs.puyonexusPackages.chainsim}/share/php/puyonexus-chainsim/public/index.php;
            '';
          };
          "${cfg.path}/assets/" = {
            alias = "${pkgs.puyonexusPackages.chainsim}/share/php/puyonexus-chainsim/public/assets/";
          };
          "= ${cfg.path}".return = "301 ${cfg.urlPrefix}/";
        };
      };
    };

    environment.systemPackages = [ pkgs.puyonexusPackages.chainsim ];

    sops.templates."puyonexus-chainsim-localsettings.php" = {
      content = mkLocalSettings {
        basePath = cfg.path;
        baseUrl = cfg.urlPrefix;
        databaseDsn = cfg.database.dsn;
        databaseUsername = cfg.database.username;
        databasePassword = cfg.database.password;
      };
      owner = config.users.users.puyonexus.name;
    };

    environment.variables = {
      PUYONEXUS_CHAINSIM_LOCALSETTINGS_PATH =
        config.sops.templates."puyonexus-chainsim-localsettings.php".path;
    };

    services.phpfpm.pools.www.phpEnv = {
      inherit (config.environment.variables) PUYONEXUS_CHAINSIM_LOCALSETTINGS_PATH;
    };
  };
}
