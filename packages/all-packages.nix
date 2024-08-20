{ pkgs, ... }:
let
  puyonexusPackages = pkgs.callPackage ./puyonexus { };
in
{
  genhostkeys = pkgs.callPackage ./genhostkeys/package.nix { };

  puyonexusHome = puyonexusPackages.home;

  puyonexusWiki = puyonexusPackages.wiki;

  puyonexusWiki1_35 = puyonexusPackages.wiki1_35;

  initWiki = pkgs.writeShellApplication {
    name = "init-wiki";

    runtimeInputs = [ pkgs.php ];

    text = ''
      set -euo pipefail
      cd ${puyonexusPackages.wiki}/share/php/puyonexus-wiki

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
      sudo -u puyonexus php maintenance/run.php update.php

      echo "Done."
    '';
  };

  updateWiki = pkgs.writeShellApplication {
    name = "update-wiki";

    text = ''
      set -euo pipefail

      cd ${puyonexusPackages.wiki}/share/php/puyonexus-wiki
      echo "Running migrations."
      sudo -u puyonexus env PUYONEXUS_WIKI_LOCALSETTINGS_PATH="$PUYONEXUS_WIKI_LOCALSETTINGS_PATH" ${pkgs.php}/bin/php maintenance/run.php update.php

      echo "Done."
    '';
  };

  multiUpdateWiki = pkgs.writeShellApplication {
    name = "multi-update-wiki";

    text = ''
      set -euo pipefail

      cd ${puyonexusPackages.wiki1_35}/share/php/puyonexus-wiki
      echo "Running migrations for MediaWiki 1.35."
      sudo -u puyonexus env PUYONEXUS_WIKI_LOCALSETTINGS_PATH="$PUYONEXUS_WIKI_LOCALSETTINGS_PATH" ${pkgs.php}/bin/php maintenance/update.php

      cd ${puyonexusPackages.wiki}/share/php/puyonexus-wiki
      echo "Running migrations for MediaWiki 1.42."
      sudo -u puyonexus env PUYONEXUS_WIKI_LOCALSETTINGS_PATH="$PUYONEXUS_WIKI_LOCALSETTINGS_PATH" ${pkgs.php}/bin/php maintenance/run.php update.php

      echo "Done."
    '';
  };

  multiUpdateWikiDump =
    let
      mkLocalSettings = import ../puyonexus/apps/wiki/make-local-settings.nix;
    in
    pkgs.writeShellApplication {
      name = "multi-update-wiki-dump";

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

        ${pkgs.gettext}/bin/envsubst "\$MYSQL_SERVER_SOCKET" <${
          pkgs.writeText "LocalSettings.php" (mkLocalSettings {
            inherit (pkgs) lib;
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

        ${pkgs.mariadb}/bin/mariadb-install-db \
          --auth-root-authentication-method=normal \
          --datadir="$MYSQL_DATA_DIR" \
          --skip-test-db \
          --skip-name-resolve \

        ${pkgs.mariadb}/bin/mariadbd \
          --no-defaults \
          --socket="$MYSQL_SERVER_SOCKET" \
          --datadir="$MYSQL_DATA_DIR" \
          &

        until ${pkgs.mariadb}/bin/mariadb --no-defaults --socket="$MYSQL_SERVER_SOCKET" --user root mysql -e 'SELECT 1'
        do
          echo "Couldn't connect to MariaDB, trying again in a second."
          sleep 1
        done

        echo "MariaDB is running. Importing Puyo Nexus database dump."
        unzstd -c "$1" \
          | ${pkgs.mariadb}/bin/mariadb \
          --no-defaults \
          --socket="$MYSQL_SERVER_SOCKET" \
          --user root

        (cd ${puyonexusPackages.wiki1_35}/share/php/puyonexus-wiki; echo "Running migrations for MediaWiki 1.35."; ${pkgs.php}/bin/php maintenance/update.php)
        (cd ${puyonexusPackages.wiki}/share/php/puyonexus-wiki; echo "Running migrations for MediaWiki 1.42."; ${pkgs.php}/bin/php maintenance/run.php update.php)

        echo "All migrations have completed. Exporting Puyo Nexus database..."

        ${pkgs.mariadb}/bin/mariadb-dump \
          --no-defaults \
          --socket="$MYSQL_SERVER_SOCKET" \
          --user root puyonexus \
          | zstd - -o "$2"

        echo "Done."
      '';
    };
}
