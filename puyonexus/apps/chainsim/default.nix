{ config, lib, ... }:
let
  cfg = config.puyonexus.chainsim;
in
{
  options = {
    puyonexus.chainsim = {
      enable = lib.mkEnableOption "Puyo Nexus Chainsim";
    };
  };

  config = lib.mkIf cfg.enable {
    # TODO
  };
}
