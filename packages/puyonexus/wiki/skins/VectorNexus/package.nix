{
  stdenvNoCC,
  fetchgit,
  puyonexusHome,
}:
stdenvNoCC.mkDerivation {
  pname = "mediawiki-skins-VectorNexus";
  version = "unstable";
  src = ./.;

  vector = fetchgit {
    url = "https://gerrit.wikimedia.org/r/mediawiki/skins/Vector";
    rev = "02287c6b1cf9dfc0f391bd00e0bb481d3691adc5";
    hash = "sha256-uKaOyU+33XAyBjVlZ5cUH+9INhpLuMn5hLUZ2uXsKS0=";
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
