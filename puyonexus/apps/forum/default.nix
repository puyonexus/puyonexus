{ config, lib, ... }:
let
  cfg = config.puyonexus.forum;
in
{
  options = {
    puyonexus.forum = {
      enable = lib.mkEnableOption "Puyo Nexus Forum";
    };
  };

  config = lib.mkIf cfg.enable {
    # TODO
  };
}
