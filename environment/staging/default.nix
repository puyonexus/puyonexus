{ config, ... }:
{
  imports = [ ./.. ];

  config = {
    puyonexus.environment.name = "staging";
    puyonexus.domain.root = "puyonexus-staging.com";
    puyonexus.mysql.local.enable = true;
    puyonexus.wiki.enableEmail = false;
    puyonexus.home.robots.denyAll = true;
    puyonexus.home.navbarText.enable = true;
    puyonexus.home.navbarText.string = "Staging Mode (${config.puyonexus.rev})";

    # Use external MTA in staging
    puyonexus.mail.enableExternalMta = true;
  };
}
