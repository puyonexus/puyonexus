{ config, ... }:
let
  cfg = config.puyonexus.mysql;
in
{
  imports = [
    ./local.nix
    ./remote.nix
  ];

  config = {
    assertions = [
      {
        assertion = cfg.local.enable != cfg.remote.enable;
        message = "one and only one MySQL provider should be enabled";
      }
    ];
  };
}
