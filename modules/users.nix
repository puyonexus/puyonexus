{
  pkgs,
  config,
  lib,
  ...
}:
{
  options = {
    puyonexus.users = {
      basicAuthFile = lib.mkOption { type = lib.types.nullOr lib.types.path; };
    };
  };

  config = {
    puyonexus.users.basicAuthFile = lib.mkDefault (
      pkgs.writeText "nginx-auth" ''
        john:${config.users.users.john.hashedPassword}
      ''
    );
    users = {
      mutableUsers = false;
      groups.puyonexus = {
        gid = 10000;
      };
      users.puyonexus = {
        isSystemUser = true;
        uid = 10000;
        group = config.users.groups.puyonexus.name;
      };
      users.john = {
        isNormalUser = true;
        extraGroups = [ "wheel" ];
        hashedPassword = "$2b$05$zlifC3l3di8o7Wh1lUaVAuXLQCMJwPM25qXl09l8CzByZCzI2suC.";
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIgZ9V1xE87W7TXaySAvHpAM9QQ8IOc8qItnhh659d/e john@nullptr"
        ];
      };
      users.root = {
        openssh.authorizedKeys.keys = builtins.concatLists [
          config.users.users.john.openssh.authorizedKeys.keys
        ];
      };
    };
  };
}
