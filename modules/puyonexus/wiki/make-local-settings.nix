{
  lib,
  server,
  path ? "/wiki",
  scriptPath ? "/mediawiki",
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
  redisSocket ? null,
  enableEmail,
  maintenanceMessage ? null,
}:
let
  mkNowDoc = value: "<<<'ENDVAL'\n${value}\nENDVAL";
in
''
  <?php
  # URL setup
  $wgServer = ${mkNowDoc server};
  $wgScriptPath = ${mkNowDoc "${server}${scriptPath}"};
  $wgStylePath = ${mkNowDoc "${server}${scriptPath}/skins"};
  $wgArticlePath = '${path}/$1';
  $wgLogo = '/images/wiki/logo.png';

  ${lib.optionalString (maintenanceMessage != null) ''
    # MAINTENANCE MODE
    # --
    # Set read-only outside of CLI so we can still update the database/etc.
    # https://www.mediawiki.org/wiki/Manual:$wgReadOnly
    $wgReadOnly = ( PHP_SAPI === 'cli' ) ? false : ${mkNowDoc maintenanceMessage};
    ${lib.optionalString (redisSocket == null) ''
      # There is no Redis cache available: maintenance mode will disable caching.
      # https://www.mediawiki.org/wiki/Manual:$wgReadOnly#DB_caching
      $wgMessageCacheType = $wgMainCacheType = $wgParserCacheType = $wgSessionCacheType = CACHE_NONE;
      $wgLocalisationCacheConf['storeClass'] = 'LCStoreNull';
    ''}
    # --
  ''}

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
  $wgPFEnableStringFunctions = true;

  # Permissions
  $wgLogRestrictions["newusers"] = 'moderation';
  $wgAddGroups['sysop'][] = 'automoderated';
  $wgRemoveGroups['sysop'][] = 'automoderated';
  $wgGroupPermissions['*']['move'] = false;
  $wgGroupPermissions['*']['edit'] = false;
  $wgGroupPermissions['*']['createaccount'] = true;
  $wgGroupPermissions['*']['abusefilter-log-detail'] = true;
  $wgGroupPermissions['*']['abusefilter-view'] = true;
  $wgGroupPermissions['*']['abusefilter-log'] = true;
  $wgGroupPermissions['user']['move'] = false;
  $wgGroupPermissions['user']['edit'] = true;
  $wgGroupPermissions['user']['move-categorypages'] = false;
  $wgGroupPermissions['user']['movefile'] = false;
  $wgGroupPermissions['user']['move-subpages'] = false;
  $wgGroupPermissions['user']['move-rootuserpages'] = false;
  $wgGroupPermissions['user']['sendemail'] = false;
  $wgGroupPermissions['bot']['skip-moderation'] = true;
  $wgGroupPermissions['checkuser']['moderation-checkuser'] = false;
  $wgGroupPermissions['automoderated']['move'] = true;
  $wgGroupPermissions['automoderated']['move-categorypages'] = true;
  $wgGroupPermissions['automoderated']['movefile'] = true;
  $wgGroupPermissions['automoderated']['move-subpages'] = true;
  $wgGroupPermissions['automoderated']['move-rootuserpages'] = true;
  $wgGroupPermissions['automoderated']['sendemail'] = true;
  $wgGroupPermissions['automoderated']['move'] = true;
  $wgGroupPermissions['sysop']['abusefilter-modify'] = true;
  $wgGroupPermissions['sysop']['moderation'] = true;
  $wgGroupPermissions['sysop']['skip-moderation'] = true;
  $wgGroupPermissions['sysop']['checkuser'] = true;
  $wgGroupPermissions['sysop']['checkuser-log'] = true;
  $wgGroupPermissions['sysop']['abusefilter-private'] = true;
  $wgGroupPermissions['sysop']['abusefilter-modify-restricted'] = true;
  $wgGroupPermissions['sysop']['abusefilter-revert'] = true;
  $wgGroupPermissions['sysop']['editsitecss'] = true;
  $wgGroupPermissions['sysop']['editsitejs'] = true;

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
  ${lib.optionalString (redisSocket != null) ''
    $wgObjectCaches['redis'] = [
      'class'   => 'RedisBagOStuff',
      'servers' => [ '${redisSocket}' ],
    ];
    $wgMainCacheType = 'redis';
  ''}
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

  # Enable subpages in the main namespace
  $wgNamespacesWithSubpages[NS_MAIN] = true;

  # Add a PPQ namespace (Experimental!)
  define("NS_PPQ", 3000);
  define("NS_PPQ_TALK", 3001);
  $wgExtraNamespaces[NS_PPQ] = "PPQ";
  $wgExtraNamespaces[NS_PPQ_TALK] = "PPQ_talk";
  $wgContentNamespaces[] = NS_PPQ;

  # Misc
  $wgTemplateStylesAllowedUrls['audio'] = ["<^/mediawiki/images/>"];
  $wgTemplateStylesAllowedUrls['image'] = ["<^/mediawiki/images/>"];
  $wgTemplateStylesAllowedUrls['svg'] = ["<^/mediawiki/images/>"];
  $wgTemplateStylesAllowedUrls['font'] = [];
  $wtTemplateStylesAllowedUrls['namespace'] = ["<.>"];
''
