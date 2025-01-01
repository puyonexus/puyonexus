{ config, ... }:
{
  imports = [ ./.. ];

  config = {
    puyonexus.environment.name = "staging";
    puyonexus.domain.root = "puyonexus-staging.com";
    puyonexus.mysql.local.enable = true;
    puyonexus.home.robots.denyAll = true;
    puyonexus.home.navbarText.enable = true;
    puyonexus.home.navbarText.string = "Staging Mode (${config.puyonexus.rev})";

    # Use external MTA in staging
    puyonexus.mail.externalMta.enable = true;
    puyonexus.mail.domain = "sandbox2cad93530245423fa4399fafb87f1f5e.mailgun.org";
  };
}
