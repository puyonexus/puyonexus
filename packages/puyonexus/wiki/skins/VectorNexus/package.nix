{ stdenvNoCC, vector }:
stdenvNoCC.mkDerivation {
  pname = "mediawiki-skins-VectorNexus";
  version = "unstable";
  src = ./.;

  inherit vector;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/includes/templates
    cp -r $vector/includes/templates/* $out/includes/templates
    chmod -R +w $out/includes/templates
    cp -r . $out

    runHook postInstall
  '';
}
