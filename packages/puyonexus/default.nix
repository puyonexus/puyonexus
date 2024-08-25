{ pkgs, lib, ... }:
lib.makeScope pkgs.newScope (
  self:
  let
    inherit (self) callPackage;
  in
  {
    chainsim = callPackage ./chainsim { };

    forum = callPackage ./forum { };

    home = callPackage ./home { };

    wiki = callPackage ./wiki { };

    wiki1_35 = callPackage ./wiki1_35 { };
  }
)
