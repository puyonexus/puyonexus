{
  stdenvNoCC,
  fetchFromGitHub,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "puyonexus-home";
  version = "unstable";

  src = fetchFromGitHub {
    owner = "puyonexus";
    repo = "home";
    rev = "0bf9bf5f64dc9ac7d8f5cf46f8a5ae28da88acaa";
    hash = "sha256-r0TaUMsFqO01K1t/XjI2GjXHhsEUAsgcETUI2WsIrj0=";
  };

  installPhase = ''
    mkdir -p "$out"/share/php/
    cp -r www "$out"/share/php/"${finalAttrs.pname}"/
  '';
})
