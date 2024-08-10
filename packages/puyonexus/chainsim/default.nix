{
  lib,
  stdenv,
  fetchFromGitHub,
  php,
}:
php.buildComposerProject {
  pname = "puyonexus-chainsim";
  version = "unstable";

  src = fetchFromGitHub {
    owner = "puyonexus";
    repo = "puyosim";
    rev = "4f8e37ead837d7c5401a7c871b77dedd1b022e96";
    hash = "sha256-O1pOsu5273VriSiaS38DzO4t934spjfIBg3loCaSBgA=";
  };

  vendorHash = "sha256-UNlev3W1LKc3Jyo9WdGZmoXm8aFb+3JsX1XkJ2KWFRU=";
}
