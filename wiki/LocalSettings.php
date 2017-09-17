<?php
if (!defined('MEDIAWIKI')) { exit; }

# Configuration
$wgSitename = $_ENV["MEDIAWIKI_SITENAME"];
$wgMetaNamespace = $_ENV["MEDIAWIKI_NAMESPACE"];
$wgLanguageCode = 'en';
$wgSecretKey = $_ENV["MEDIAWIKI_SECRETKEY"];
$wgUpgradeKey = $_ENV["MEDIAWIKI_UPGRADEKEY"];
$wgScriptPath = '/mediawiki';
$wgScriptExtension  = '.php';
$wgArticlePath = '/wiki/$1';
$wgServer = $_ENV["SITE_ROOT"];
$wgStylePath = '$wgScriptPath/skins';
$wgLogo = '/images/wiki/logo.png';
$wgEnableEmail = true;
$wgEnableUserEmail = true;
$wgEmergencyContact = $_ENV["MEDIAWIKI_CONTACT"];
$wgPasswordSender = $_ENV["MEDIAWIKI_CONTACT"];
$wgEnotifUserTalk = false;
$wgEnotifWatchlist = false;
$wgEmailAuthentication = true;
$wgEnableUploads = true;
$wgAllowExternalImages = true;
$wgAllowCopyUploads = true;
$wgCopyUploadsFromSpecialUpload = true;
$wgUseInstantCommons = false;
$wgShellLocale = 'en_US.utf8';
$wgSpamBlacklistFiles = array(); # Don't use WikiMedia blacklist

# Permissions
$wgLogRestrictions["newusers"] = 'moderation';
$wgAddGroups['sysop'][] = 'automoderated';
$wgRemoveGroups['sysop'][] = 'automoderated';
$wgGroupPermission['*']['move'] = false;
$wgGroupPermissions['*']['edit'] = false;
$wgGroupPermissions['*']['createaccount'] = true;
$wgGroupPermissions['*']['abusefilter-log-detail'] = true;
$wgGroupPermissions['*']['abusefilter-view'] = true;
$wgGroupPermissions['*']['abusefilter-log'] = true;
$wgGroupPermissions['user']['move'] = false;
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

# Database
$wgDBtype = 'mysqli';
$wgDBserver = "{$_ENV["MYSQL_HOSTNAME"]}:3306";
$wgDBname = $_ENV["MYSQL_DATABASE"];
$wgDBuser = $_ENV["MYSQL_USERNAME"];
$wgDBpassword = $_ENV["MYSQL_PASSWORD"];
$wgDBprefix = 'mw_';
$wgDBTableOptions = 'ENGINE=InnoDB, DEFAULT CHARSET=utf8';
$wgDBmysql5 = false;

# Caching
$wgMainCacheType = CACHE_NONE; # TODO
$wgMemCachedServers = array();
$wgCacheDirectory = "$IP/cache";

# Extensions
require_once('./LocalSettings.Extensions.php');

# Skins
require_once('./LocalSettings.Skins.php');
