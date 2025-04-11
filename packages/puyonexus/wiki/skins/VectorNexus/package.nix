{ stdenvNoCC, fetchFromGitHub }:
stdenvNoCC.mkDerivation {
  pname = "mediawiki-skins-VectorNexus";
  version = "unstable";
  src = ./.;

  vector = fetchFromGitHub {
    owner = "Wikimedia";
    repo = "mediawiki-skins-Vector";
    rev = "81ba66638332b4ad40fba30c1794d14f6f666d35";
    hash = "sha256-vY1ADccHcOSCSWsmi12mWU8rRrIT6ebcvpRNms0EBZc=";
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
