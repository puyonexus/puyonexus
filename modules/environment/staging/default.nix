{ lib, config, ... }:
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

    # Reduce memory usage in staging
    services.phpfpm.pools.www.settings = {
      "pm.max_children" = lib.mkForce 10;
      "pm.start_servers" = lib.mkForce 1;
      "pm.min_spare_servers" = lib.mkForce 1;
      "pm.max_spare_servers" = lib.mkForce 3;
    };
    services.redis.servers.wiki.settings = {
      maxmemory = lib.mkForce "128mb";
    };
  };
}
