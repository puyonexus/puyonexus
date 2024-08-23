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
    rev = "234a706bb11a651f1a6beab943afceb6a26b3b79";
    hash = "sha256-T0zz0YwU+oUHN2lAfL2POGqRYWtJB3z8A9hxDsFoi3E=";
  };

  postPatch = ''
    cp ${localSettings} config/localsettings.php
  '';

  vendorHash = "sha256-F2QdqqGW02m+2a5cI9c/cYo3dH7+YV9MelsEKVk2f2I=";
}
