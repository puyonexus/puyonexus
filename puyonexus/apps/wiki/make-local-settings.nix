{
  lib,
  server,
  domain,
  secretKey,
  upgradeKey,
  uploadDir,
  mysqlServer,
  mysqlUsername,
  mysqlPassword,
  smtpHost,
  smtpPort,
  smtpUsername,
  smtpPassword,
  enableEmail,
}:
let
  mkNowDoc = value: "<<<'ENDVAL'\n${value}\nENDVAL";
in
''
  <?php
  # URL setup
  $wgServer = ${mkNowDoc server};
  $wgScriptPath = ${mkNowDoc "${server}/mediawiki"};
  $wgStylePath = ${mkNowDoc "${server}/mediawiki/skins"};
  $wgArticlePath = '/wiki/$1';
  $wgLogo = '/images/wiki/logo.png';

  # General Configuration
  $wgSitename = 'Puyo Nexus Wiki';
  $wgMetaNamespace = 'PuyoNexus';
  $wgLanguageCode = 'en';
  $wgSecretKey = ${mkNowDoc secretKey};
  $wgUpgradeKey = ${mkNowDoc upgradeKey};
  $wgScriptExtension  = '.php';
  $wgEnotifUserTalk = false;
  $wgEnotifWatchlist = false;
  $wgEnableUploads = true;
  $wgUploadDirectory = ${mkNowDoc uploadDir};
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
  $wgDBserver = ${mkNowDoc mysqlServer};
  $wgDBname = 'puyonexus';
  $wgDBuser = ${mkNowDoc mysqlUsername};
  $wgDBpassword = ${mkNowDoc mysqlPassword};
  $wgDBprefix = 'mw_';
  $wgDBTableOptions = 'ENGINE=InnoDB, DEFAULT CHARSET=utf8';

  # E-mail
  $wgEnableEmail = ${lib.boolToString enableEmail};
  $wgEnableUserEmail = true;
  $wgEmailAuthentication = true;
  $wgEmergencyContact = ${mkNowDoc "support@${domain}"};
  $wgPasswordSender = ${mkNowDoc "support@${domain}"};
  $wgSMTP = array(
    'auth' => true,
    'host' => ${mkNowDoc smtpHost},
    'port' => ${mkNowDoc smtpPort},
    'username' => ${mkNowDoc smtpUsername},
    'password' => ${mkNowDoc smtpPassword},
    'IDHost' => ${mkNowDoc domain},
  );
  $wgPasswordSender = ${mkNowDoc "no-reply@${domain}"};
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
  $wgVectorUseSimpleSearch = true;
  $wgDefaultUserOptions['usebetatoolbar'] = 1;
  $wgDefaultUserOptions['usebetatoolbar-cgd'] = 1;
  $wgDefaultUserOptions['wikieditor-preview'] = 1;
  $wgDefaultUserOptions['vector-collapsiblenav'] = 1;
''
