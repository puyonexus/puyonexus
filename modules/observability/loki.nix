{ config, lib, ... }:
let
  cfg = config.puyonexus.loki;
in
{
  options = {
    puyonexus.loki = {
      enable = lib.mkEnableOption "Loki logging daemon";
      listenPort = lib.mkOption {
        type = lib.types.int;
        default = 3030;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.loki = {
      enable = true;
      configuration = {
        server.http_listen_port = cfg.listenPort;
        auth_enabled = false;
        common = {
          path_prefix = "/var/lib/loki/";
        };
        ingester = {
          lifecycler = {
            address = "127.0.0.1";
            ring = {
              kvstore = {
                store = "inmemory";
              };
              replication_factor = 1;
            };
          };
          chunk_idle_period = "1h";
          max_chunk_age = "1h";
          chunk_target_size = 999999;
          chunk_retain_period = "30s";
        };
        schema_config = {
          configs = [
            {
              from = "2023-12-29";
              store = "tsdb";
              object_store = "filesystem";
              schema = "v13";
              index = {
                prefix = "index_";
                period = "24h";
              };
            }
          ];
        };
        storage_config = {
          filesystem = {
            directory = "/var/lib/loki/chunks";
          };
        };
        limits_config = {
          reject_old_samples = true;
          reject_old_samples_max_age = "168h";
        };
        table_manager = {
          retention_deletes_enabled = false;
          retention_period = "0s";
        };
        compactor = {
          working_directory = "/var/lib/loki";
          compactor_ring = {
            kvstore = {
              store = "inmemory";
            };
          };
        };
      };
    };
  };
}
