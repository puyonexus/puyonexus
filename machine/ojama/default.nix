{
  imports = [
    ../../puyonexus
  ];

  config = {
    system.stateVersion = "24.05";
    networking.hostName = "ojama";

    # TLS certificates via ACME
    puyonexus.acme.enable = true;

    # OpenSSH
    puyonexus.ssh.enable = true;

    # Public web apps
    puyonexus.chainsim.enable = true;
    puyonexus.forum.enable = true;
    puyonexus.home.enable = true;
    puyonexus.wiki.enable = true;

    # Internal web apps
    puyonexus.grafana.enable = true;

    # Observability (Prometheus, Loki, Grafana, etc.)
    puyonexus.observability.enableMonolith = true;
  };
}
