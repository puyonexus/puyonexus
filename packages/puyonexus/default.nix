{ pkgs, ... }:
{
  home = pkgs.callPackage ./home { };

  wiki = pkgs.callPackage ./wiki { };
}
