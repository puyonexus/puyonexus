{ config, lib, pkgs, ... }:
let
  cfg = config.puyonexus.home;
in
{
  options = {
    puyonexus.home = {
      enable = lib.mkEnableOption "Puyo Nexus Homepage";
    };
  };

  config = lib.mkIf cfg.enable {
    puyonexus.php.enable = true;

    services.nginx = {
      enable = true;
      virtualHosts.${config.puyonexus.domain.root} = {
        locations = {
          "/" = {
            alias = "${pkgs.puyonexusHome}/share/php/puyonexus-home/";
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

    environment.systemPackages = [ pkgs.puyonexusHome ];
  };
}
