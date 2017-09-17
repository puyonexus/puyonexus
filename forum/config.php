<?php
$dbms = 'mysqli';
$dbhost = $_ENV["MYSQL_HOSTNAME"];
$dbport = 3306;
$dbname = $_ENV["MYSQL_DATABASE"];
$dbuser = $_ENV["MYSQL_USERNAME"];
$dbpasswd = $_ENV["MYSQL_PASSWORD"];
$table_prefix = 'phpbb_';
$acm_type = 'file';
$load_extensions = '';
@define('PHPBB_INSTALLED', true);
