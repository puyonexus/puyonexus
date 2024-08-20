{
  imports = [ ./.. ];

  config = {
    puyonexus.environment.name = "staging";
    puyonexus.domain.root = "puyonexus-staging.com";
    puyonexus.mysql.local.enable = true;
    puyonexus.wiki.enableEmail = false;
    puyonexus.home.robots.denyAll = true;

    # Use external MTA in staging
    puyonexus.mail.enableExternalMta = true;
  };
}
