{ config, lib, ... }:
let
  cfg = config.puyonexus.domain;
in
{
  options = {
    puyonexus.domain = {
      root = lib.mkOption {
        type = lib.types.str;
      };
    };
  };

  config = {
    networking.domain = cfg.root;
  };
}
