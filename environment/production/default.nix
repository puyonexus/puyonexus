{
  imports = [ ./.. ];

  config = {
    puyonexus.environment.name = "production";
    puyonexus.domain.root = "puyonexus.com";
    puyonexus.mysql.local.enable = true;
    puyonexus.home.navbarText.enable = false;

    # Use external MTA in production
    puyonexus.mail.enableExternalMta = true;
  };
}
