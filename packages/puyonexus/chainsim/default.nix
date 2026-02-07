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
    rev = "7f009eb6419bb41be5232e016ca3f59081dffe8a";
    hash = "sha256-AeNScBZzb0XLX6gKi/HQgYlLd7xW6ta0zfZAjufhTaM=";
  };

  postPatch = ''
    cp ${localSettings} config/localsettings.php
  '';

  vendorHash = "sha256-Cpm12hmo8rXCEUnoppiQDDb5mBneQEUaPShKBQDsLRo=";
}
