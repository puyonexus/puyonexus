{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.puyonexus.home;
in
{
  options = {
    puyonexus.home = {
      enable = lib.mkEnableOption "Puyo Nexus Homepage";
      domain = lib.mkOption {
        type = lib.types.str;
        default = config.puyonexus.domain.root;
      };
      robots = {
        denyAll = lib.mkOption {
          type = lib.types.bool;
          default = false;
        };
      };
      navbarText = {
        enable = lib.mkEnableOption "Navbar Text";
        string = lib.mkOption { type = lib.types.str; };
      };
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
                fastcgi_intercept_errors off;
              }
            '';
          };
          "= /assets/css/common.css" = lib.mkIf cfg.navbarText.enable {
            alias = "${pkgs.stdenvNoCC.mkDerivation {
              name = "common.css";
              dontUnpack = true;
              dontBuild = true;
              installPhase = ''
                cat > $out < ${pkgs.puyonexusHome}/share/php/puyonexus-home/assets/css/common.css
                cat >> $out << 'EOF'
                ul.pn-nav:first-child::after {
                  content: '${cfg.navbarText.string}';
                  color: #ff8300;
                  display: inline-block;
                  line-height: 20px;
                  padding: 20px;
                  position: absolute;
                }
                @media (max-width: 767px) {
                  ul.pn-nav:first-child::after {
                    position: static;
                  }
                }
                EOF
              '';
            }}";
          };
          "= /robots.txt" = lib.mkIf cfg.robots.denyAll {
            alias = pkgs.writeText "robots.txt" ''
              User-agent: *
              Disallow: /
            '';
          };
        };
        extraConfig = ''
          error_page 401 /errors/401.html;
          error_page 404 /errors/404.html;
          error_page 500 502 503 504 /errors/500.html;
        '';
      };
    };

    environment.systemPackages = [ pkgs.puyonexusHome ];

    environment.variables = {
      PUYONEXUS_BASE_URL =
        let
          scheme = if config.puyonexus.acme.enable then "https" else "http";
        in
        "${scheme}://${cfg.domain}";
    };

    services.phpfpm.pools.www.phpEnv = {
      inherit (config.environment.variables) PUYONEXUS_BASE_URL;
    };
  };
}
