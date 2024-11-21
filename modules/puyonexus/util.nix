{ lib, config, ... }:
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
            sudo -u puyonexus env PUYONEXUS_WIKI_LOCALSETTINGS_PATH="$PUYONEXUS_WIKI_LOCALSETTINGS_PATH" php maintenance/run.php update.php --quick "''${@}"

            echo "Done."
          '';
        };
      })
    ];
  };
}
