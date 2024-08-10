{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.puyonexus.wiki;
in
{
  options = {
    puyonexus.wiki = {
      enable = lib.mkEnableOption "Puyo Nexus Wiki";
      smtp = {
        hostPath = lib.mkOption { type = lib.types.str; };
        portPath = lib.mkOption { type = lib.types.str; };
        usernamePath = lib.mkOption { type = lib.types.str; };
        passwordPath = lib.mkOption { type = lib.types.str; };
      };
      mysql = {
        server = lib.mkOption { type = lib.types.str; };
        usernamePath = lib.mkOption { type = lib.types.str; };
        passwordPath = lib.mkOption { type = lib.types.str; };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    puyonexus.php.enable = true;

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
          "/wiki/images/" = {
            # TODO: uploads directory
            #alias = withTrailingSlash cfg.uploadsDir;
            # TODO: make sure images directory is marked no-sniff
          };
          "/wiki/images/deleted" = {
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
    ];

    environment.etc."puyonexus/wiki/LocalSettings.php" =
      let
        scheme = if config.puyonexus.acme.enable then "https" else "http";
        suffix = if config.puyonexus.acme.enable then "" else ":8080";
        domain = config.puyonexus.domain.root;
        server = "${scheme}://${domain}${suffix}";
      in
      {
        text = ''
          <?php
          # URL setup
          $wgServer = '${server}';
          $wgScriptPath = '${server}/mediawiki';
          $wgStylePath = '${server}/mediawiki/skins';
          $wgArticlePath = '/wiki/$1';
          $wgLogo = '/images/wiki/logo.png';

          # General Configuration
          $wgSitename = 'Puyo Nexus Wiki';
          $wgMetaNamespace = 'PuyoNexus';
          $wgLanguageCode = 'en';
          $wgSecretKey = 'fakesecretkey';
          $wgUpgradeKey = 'fakeupgradekey';
          $wgScriptExtension  = '.php';
          $wgEnotifUserTalk = false;
          $wgEnotifWatchlist = false;
          $wgEnableUploads = true;
          $wgAllowExternalImages = true;
          $wgAllowCopyUploads = true;
          $wgCopyUploadsFromSpecialUpload = true;
          $wgUseInstantCommons = false;
          $wgShellLocale = 'en_US.utf8';
          $wgSpamBlacklistFiles = array(); # Don't use WikiMedia blacklist
          $wgJobRunRate = 0;
          $wgModerationEnable = true;
          $wgMiserMode = true;
          $wgMaxImageArea = 50000000;

          # Database
          $wgDBtype = 'mysql';
          $wgDBserver = '${cfg.mysql.server}';
          $wgDBname = 'puyonexus';
          $wgDBuser = file_get_contents('${cfg.mysql.usernamePath}');
          $wgDBpassword = file_get_contents('${cfg.mysql.passwordPath}');
          $wgDBprefix = 'mw_';
          $wgDBTableOptions = 'ENGINE=InnoDB, DEFAULT CHARSET=utf8';

          # E-mail
          $wgEnableEmail = true;
          $wgEnableUserEmail = true;
          $wgEmailAuthentication = true;
          $wgEmergencyContact = 'support@${domain}';
          $wgPasswordSender = 'support@${domain}';
          $wgSMTP = array(
            'auth' => true,
            'host' => file_get_contents('${cfg.smtp.hostPath}'),
            'port' => file_get_contents('${cfg.smtp.portPath}'),
            'username' => file_get_contents('${cfg.smtp.usernamePath}'),
            'password' => file_get_contents('${cfg.smtp.passwordPath}'),
            'IDHost' => '${domain}',
          );
          $wgPasswordSender = "no-reply@${domain}";
          $wgUserEmailUseReplyTo = true;
          $wgShowExceptionDetails = true;

          # Caching
          $wgMainCacheType = CACHE_NONE; # TODO
          $wgMemCachedServers = array();
          $wgCacheDirectory = "/tmp/puyonexus-wiki/cache/$wgDBname";

          # CAPTCHA
          wfLoadExtension('ConfirmEdit/QuestyCaptcha');
          $wgCaptchaClass = 'QuestyCaptcha';
          $wgCaptchaQuestions[] = array(
            'question' => 'What is the name (in English) of the protagonist\'s pet/sidekick in the video game Puyo Puyo?',
            'answer' => 'Carbuncle'
          );

          # Skins
          $wgDefaultSkin = 'vectornexus';
          # $wgDefaultSkin = 'vector';
          $wgVectorUseSimpleSearch = true;
          $wgDefaultUserOptions['usebetatoolbar'] = 1;
          $wgDefaultUserOptions['usebetatoolbar-cgd'] = 1;
          $wgDefaultUserOptions['wikieditor-preview'] = 1;
          $wgDefaultUserOptions['vector-collapsiblenav'] = 1;
        '';
      };
  };
}
