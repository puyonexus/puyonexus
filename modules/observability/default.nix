{
  imports = [
    ./grafana

    ./loki.nix
    ./monolith.nix
    ./prometheus-exporters.nix
    ./prometheus.nix
    ./promtail.nix
  ];
}
