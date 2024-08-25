final: prev:
let
  inherit (final) callPackage;
in
{
  genhostkeys = callPackage ./genhostkeys/package.nix { };

  puyonexusPackages = callPackage ./puyonexus { };
}
