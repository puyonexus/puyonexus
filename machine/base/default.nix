{ pkgs, ... }:
{
  imports = [
    ../../puyonexus/openssh.nix
    ../../puyonexus/users.nix
  ];

  config = {
    system.stateVersion = "24.05";
    networking.hostName = "base";

    # So that the database can be imported ahead of time.
    services.mysql = {
      enable = true;
      package = pkgs.mariadb;
      initialDatabases = [ { name = "puyonexus"; } ];
      ensureUsers = [
        {
          name = "puyonexus";
          ensurePermissions = {
            # See https://phabricator.wikimedia.org/T193552.
            "puyonexus.*" = "ALL PRIVILEGES";
          };
        }
      ];
    };

    puyonexus.ssh.enable = true;
  };
}
