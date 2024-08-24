{ pkgs, ... }:
{
  chainsim = pkgs.callPackage ./chainsim { };

  forum = pkgs.callPackage ./forum { };

  home = pkgs.callPackage ./home { };

  wiki = pkgs.callPackage ./wiki { };

  wiki1_35 = pkgs.callPackage ./wiki1_35 { };
}
