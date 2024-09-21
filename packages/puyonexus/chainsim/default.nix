{
  lib,
  stdenv,
  fetchFromGitHub,
  php,
  writeText,
}:
let
  localSettings = writeText "localsettings.php" "<?php return require_once(getenv('PUYONEXUS_CHAINSIM_LOCALSETTINGS_PATH')); ?>";
in
php.buildComposerProject {
  pname = "puyonexus-chainsim";
  version = "4.3.0";

  src = fetchFromGitHub {
    owner = "puyonexus";
    repo = "puyosim";
    rev = "f1d7e8a0b3060c6ca036f11ecae249c865703d95";
    hash = "sha256-CuCjjw1ARt7pJRJ2Lws2mcyOkxghw8WUIGj52Msqk1Q=";
  };

  postPatch = ''
    cp ${localSettings} config/localsettings.php
  '';

  vendorHash = "sha256-F2QdqqGW02m+2a5cI9c/cYo3dH7+YV9MelsEKVk2f2I=";
}
