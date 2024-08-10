{ config, lib, ... }:
let
  cfg = config.puyonexus.mail;
  rootDomain = config.puyonexus.domain.root;
in
{
  options = {
    puyonexus.mail = {
      domain = lib.mkOption {
        type = lib.types.str;
        default = rootDomain;
      };
    };
  };

  imports = [
    ./external.nix
    ./mailpit.nix
  ];

  config = {
    assertions = [
      {
        assertion = cfg.enableExternalMta != cfg.enableMailpit;
        message = "one and only one MTA should be enabled";
      }
    ];
  };
}
