{
  lib,
  pkgs,
  config,
  ...
}:
{
  config = lib.mkIf config.puyonexus.php.enable {
    nixpkgs.overlays = [
      (final: prev: {
        initWiki = final.writeShellApplication {
          name = "init-wiki";

          runtimeInputs = [ config.puyonexus.php.package ];

          text = ''
            set -euo pipefail
            cd ${final.puyonexusPackages.wiki}/share/php/puyonexus-wiki

            echo -n "Enter new admin password: "
            read -rs password
            echo

            echo "Setting up initial database tables."
            sudo -u puyonexus \
              env MW_CONFIG_FILE=/fail.php PUYONEXUS_WIKI_LOCALSETTINGS_PATH="$PUYONEXUS_WIKI_LOCALSETTINGS_PATH" \
              php maintenance/run.php install.php \
              --dbuser "puyonexus" \
              --dbname "puyonexus" \
              --dbprefix "mw_" \
              --pass "$password" \
              "Puyo Nexus Wiki" "admin"

            echo "Running migrations."
            sudo -u puyonexus \
              env PUYONEXUS_WIKI_LOCALSETTINGS_PATH="$PUYONEXUS_WIKI_LOCALSETTINGS_PATH" \
              php maintenance/run.php update.php

            echo "Done."
          '';
        };

        updateForum = final.writeShellApplication {
          name = "update-forum";

          runtimeInputs = [ config.puyonexus.php.package ];

          text = ''
            set -euo pipefail

            cd ${final.puyonexusPackages.forum}/share/php/puyonexus-forum
            echo "Running migrations."
            sudo -u puyonexus env PUYONEXUS_FORUM_CONFIG_PATH="$PUYONEXUS_FORUM_CONFIG_PATH" php bin/phpbbcli.php db:migrate --safe-mode

            echo "Done."
          '';
        };

        updateWiki = final.writeShellApplication {
          name = "update-wiki";

          runtimeInputs = [ config.puyonexus.php.package ];

          text = ''
            set -euo pipefail

            cd ${final.puyonexusPackages.wiki}/share/php/puyonexus-wiki
            echo "Running migrations."
            sudo -u puyonexus env PUYONEXUS_WIKI_LOCALSETTINGS_PATH="$PUYONEXUS_WIKI_LOCALSETTINGS_PATH" php maintenance/run.php update.php

            echo "Done."
          '';
        };

        multiUpdateWiki = final.writeShellApplication {
          name = "multi-update-wiki";

          runtimeInputs = [ config.puyonexus.php.package ];

          text = ''
            set -euo pipefail

            cd ${final.puyonexusPackages.wiki1_35}/share/php/puyonexus-wiki
            echo "Running migrations for MediaWiki 1.35."
            sudo -u puyonexus env PUYONEXUS_WIKI_LOCALSETTINGS_PATH="$PUYONEXUS_WIKI_LOCALSETTINGS_PATH" php maintenance/update.php

            cd ${final.puyonexusPackages.wiki}/share/php/puyonexus-wiki
            echo "Running migrations for MediaWiki 1.42."
            sudo -u puyonexus env PUYONEXUS_WIKI_LOCALSETTINGS_PATH="$PUYONEXUS_WIKI_LOCALSETTINGS_PATH" php maintenance/run.php update.php

            echo "Done."
          '';
        };

        multiUpdateWikiDump =
          let
            mkLocalSettings = import ./wiki/make-local-settings.nix;
          in
          final.writeShellApplication {
            name = "multi-update-wiki-dump";

            runtimeInputs = [ config.puyonexus.php.package ];

            text = ''
              set -euo pipefail

              if [[ $# -ne 2 ]]; then
                echo "Invalid number of parameters." >&2
                echo "Usage: $0 <input> <output>" >&2
                echo "Note: both the input and the output is zstd-compressed." >&2
                exit 2
              fi

              # shellcheck disable=SC2064
              trap "trap - SIGTERM && kill -- -$$" SIGINT SIGTERM EXIT

              TMPDIR=$(mktemp -d --tmpdir="''${TMPDIR:-/tmp}" puyowiki.XXXXXXXXXX)
              echo "Working in $TMPDIR."

              export PUYONEXUS_WIKI_LOCALSETTINGS_PATH="$TMPDIR/LocalSettings.php"
              export MYSQL_SERVER_SOCKET="$TMPDIR/mysqld.sock"
              export MYSQL_DATA_DIR="$TMPDIR/mysql-data"

              mkdir -p "$MYSQL_DATA_DIR"

              ${final.gettext}/bin/envsubst "\$MYSQL_SERVER_SOCKET" <${
                final.writeText "LocalSettings.php" (mkLocalSettings {
                  inherit (final) lib;
                  server = "https://puyonexus.com";
                  domain = "puyonexus.com";
                  secretKey = "0";
                  upgradeKey = "0";
                  mysqlServer = "localhost:$MYSQL_SERVER_SOCKET";
                  mysqlUsername = "root";
                  mysqlPassword = "";
                  smtpHost = "255.255.255.255";
                  smtpPort = "0";
                  smtpUsername = "nosmtp";
                  smtpPassword = "nosmtp";
                  uploadDir = "/var/empty";
                  enableEmail = false;
                })
              } >"$PUYONEXUS_WIKI_LOCALSETTINGS_PATH"

              ${final.mariadb}/bin/mariadb-install-db \
                --auth-root-authentication-method=normal \
                --datadir="$MYSQL_DATA_DIR" \
                --skip-test-db \
                --skip-name-resolve \

              ${final.mariadb}/bin/mariadbd \
                --no-defaults \
                --socket="$MYSQL_SERVER_SOCKET" \
                --datadir="$MYSQL_DATA_DIR" \
                &

              until ${final.mariadb}/bin/mariadb --no-defaults --socket="$MYSQL_SERVER_SOCKET" --user root mysql -e 'SELECT 1'
              do
                echo "Couldn't connect to MariaDB, trying again in a second."
                sleep 1
              done

              echo "MariaDB is running. Importing Puyo Nexus database dump."
              unzstd -c "$1" \
                | ${final.mariadb}/bin/mariadb \
                --no-defaults \
                --socket="$MYSQL_SERVER_SOCKET" \
                --user root

              (cd ${final.puyonexusPackages.wiki1_35}/share/php/puyonexus-wiki; echo "Running migrations for MediaWiki 1.35."; php maintenance/update.php)
              (cd ${final.puyonexusPackages.wiki}/share/php/puyonexus-wiki; echo "Running migrations for MediaWiki 1.42."; php maintenance/run.php update.php)

              echo "All migrations have completed. Exporting Puyo Nexus database..."

              ${final.mariadb}/bin/mariadb-dump \
                --no-defaults \
                --socket="$MYSQL_SERVER_SOCKET" \
                --user root puyonexus \
                | zstd - -o "$2"

              echo "Done."
            '';
          };
      })
    ];
  };
}
