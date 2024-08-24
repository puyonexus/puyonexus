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
    rev = "aad1853bf61896924336e6607d44de5b90f60bab";
    hash = "sha256-F/nmb3ScS9p3T+IjDt0LHJ+jDKspAu32NlYdOXJWVD8=";
  };

  postPatch = ''
    cp ${localSettings} config/localsettings.php
  '';

  vendorHash = "sha256-F2QdqqGW02m+2a5cI9c/cYo3dH7+YV9MelsEKVk2f2I=";
}
