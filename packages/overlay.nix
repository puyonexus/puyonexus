final: prev:
let
  inherit (final) callPackage;
in
{
  # CVE-2026-126714
  php83 =
    if final.lib.versionOlder prev.php83.version "8.3.37" then
      prev.php83.buildEnv {
        version = "8.3.37";
        hash = "sha256-eDe0PNThjbXerCHubwCGbkd5pwXy5U+uqDyKbPVv0dg=";
      }
    else
      prev.php83;

  genhostkeys = callPackage ./genhostkeys/package.nix { };

  genmwhashes = callPackage ./genmwhashes/package.nix { };

  puyonexusPackages = callPackage ./puyonexus { };
}
