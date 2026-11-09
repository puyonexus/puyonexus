final: prev:
let
  inherit (final) callPackage;
in
{
  genhostkeys = callPackage ./genhostkeys/package.nix { };

  genmwhashes = callPackage ./genmwhashes/package.nix { };

  puyonexusPackages = callPackage ./puyonexus { };
}
