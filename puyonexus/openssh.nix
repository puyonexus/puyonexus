{ config, lib, ... }:
let
  cfg = config.puyonexus.ssh;
in
{
  options = {
    puyonexus.ssh = {
      enable = lib.mkEnableOption "ssh";
      port = lib.mkOption {
        type = lib.types.int;
        default = 22;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.openssh = {
      enable = true;
      ports = lib.singleton cfg.port;
      settings = {
        PrintMotd = true;
        PasswordAuthentication = false;
      };
    };
  };
}
