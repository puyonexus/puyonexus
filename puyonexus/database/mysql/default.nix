{ config, lib, ... }:
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

    sops.secrets =
      let
        puyonexusOwnership = {
          owner = config.users.users.puyonexus.name;
        };
      in
      {
        "puyonexus/mysql/username" = {
          key = "mysql/username";
        } // puyonexusOwnership;
        "puyonexus/mysql/password" = {
          key = "mysql/password";
        } // puyonexusOwnership;
      };

    puyonexus.wiki.mysql = {
      usernamePath = config.sops.secrets."puyonexus/mysql/username".path;
      passwordPath = config.sops.secrets."puyonexus/mysql/password".path;
    };
  };
}
