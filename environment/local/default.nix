{ config, lib, ... }:
{
  imports = [ ./.. ];

  config = {
    puyonexus.environment.name = "local";
    puyonexus.domain.root = "puyonexus.localhost";
    puyonexus.mysql.local.enable = true;
    puyonexus.home.navbarText.enable = true;
    puyonexus.home.navbarText.string = "Local Dev Mode (${config.puyonexus.rev})";

    # Use local dev MTA on local environment
    puyonexus.mail.enableMailpit = true;

    # Disable badhost locally, for better experience.
    puyonexus.badhost.enable = lib.mkForce false;

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
