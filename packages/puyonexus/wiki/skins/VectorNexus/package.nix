{ stdenvNoCC, fetchFromGitHub }:
stdenvNoCC.mkDerivation {
  pname = "mediawiki-skins-VectorNexus";
  version = "unstable";
  src = ./.;

  vector = fetchFromGitHub {
    owner = "Wikimedia";
    repo = "mediawiki-skins-Vector";
    rev = "a4a127342e106a27d89253921cc771a978523a68";
    hash = "sha256-78LGB3/7tPt+T92mLtRfg4gXA/s0aNtYGtuyKYLk944=";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out/includes/templates
    cp -r $vector/includes/templates/* $out/includes/templates
    chmod -R +w $out/includes/templates
    cp -r . $out

    runHook postInstall
  '';
}
