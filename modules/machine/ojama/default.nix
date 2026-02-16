{
  imports = [ ../.. ];

  config = {
    system.stateVersion = "24.05";
    networking.hostName = "ojama";

    # TLS certificates via ACME
    puyonexus.acme.enable = true;

    # OpenSSH
    puyonexus.ssh.enable = true;

    # Public web apps
    puyonexus.badhost.enable = true;
    puyonexus.chainsim.enable = true;
    puyonexus.files.enable = true;
    puyonexus.forum.enable = true;
    puyonexus.home.enable = true;
    puyonexus.wiki.enable = true;

    # Observability (Prometheus, Loki, Grafana, etc.)
    # Disabled for now since it's not working very well.
    puyonexus.grafana.enable = false;
    puyonexus.observability.enableMonolith = false;
  };
}
