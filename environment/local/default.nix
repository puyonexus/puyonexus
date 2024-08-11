{ lib, ... }:
{
  imports = [ ./.. ];

  config = {
    puyonexus.environment.name = "local";
    puyonexus.domain.root = "puyonexus.localhost";
    puyonexus.mysql.local.enable = true;

    # Use local dev MTA on local environment
    puyonexus.mail.enableMailpit = true;

    # Local SSH setup
    services.openssh.settings = {
      PermitRootLogin = lib.mkForce "yes";
      PasswordAuthentication = lib.mkForce true;
      PermitEmptyPasswords = lib.mkForce "yes";
      ChallengeResponseAuthentication = lib.mkForce "no";
    };
    users.users.root.password = "root";
  };
}
