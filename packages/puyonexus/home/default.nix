{ stdenvNoCC }:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "puyonexus-home";
  version = "unstable";

  src = ./www;

  installPhase = ''
    mkdir -p "$out"/share/php/
    cp -r . "$out"/share/php/"${finalAttrs.pname}"/
  '';
})
