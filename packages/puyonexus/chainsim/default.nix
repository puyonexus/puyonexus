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
    rev = "ac790dab422759a0e300523e1e45d375793db889";
    hash = "sha256-TJh9JQ8H2J1DiAUoHBKCxqG4z/UnmIFrCE0bt5lZznQ=";
  };

  postPatch = ''
    cp ${localSettings} config/localsettings.php
  '';

  vendorHash = "sha256-F2QdqqGW02m+2a5cI9c/cYo3dH7+YV9MelsEKVk2f2I=";
}
