{
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
    rev = "23260899f4b15770b02fe71a92bd45126493c0ec";
    hash = "sha256-Py6DLC1bvlbbPO91Y0s80ecMqwoPdn0TbDPSZsQm/sQ=";
  };

  postPatch = ''
    cp ${localSettings} config/localsettings.php
  '';

  vendorHash = "sha256-F2QdqqGW02m+2a5cI9c/cYo3dH7+YV9MelsEKVk2f2I=";
}
