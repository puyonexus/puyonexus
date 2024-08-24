{
  mysqlHost,
  mysqlPort,
  mysqlUsername,
  mysqlPassword,
}:
let
  mkNowDoc = value: "<<<'ENDVAL'\n${value}\nENDVAL";
in
''
  <?php
  $dbms = 'mysqli';
  $dbhost = ${mkNowDoc mysqlHost};
  $dbport = ${toString mysqlPort};
  $dbname = 'puyonexus';
  $dbuser = ${mkNowDoc mysqlUsername};
  $dbpasswd = ${mkNowDoc mysqlPassword};
  $table_prefix = 'phpbb_';
  $acm_type = 'file';
  $load_extensions = "";
  @define('PHPBB_INSTALLED', true);
''
