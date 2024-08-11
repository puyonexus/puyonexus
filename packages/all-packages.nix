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
        env MW_CONFIG_FILE=/fail.php \
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
      sudo -u puyonexus ${pkgs.php}/bin/php maintenance/run.php update.php

      echo "Done."
    '';
  };

  multiUpdateWiki = pkgs.writeShellApplication {
    name = "multi-update-wiki";

    text = ''
      set -euo pipefail

      cd ${puyonexusPackages.wiki1_35}/share/php/puyonexus-wiki
      echo "Running migrations for MediaWiki 1.35."
      sudo -u puyonexus ${pkgs.php}/bin/php maintenance/update.php

      cd ${puyonexusPackages.wiki}/share/php/puyonexus-wiki
      echo "Running migrations for MediaWiki 1.42."
      sudo -u puyonexus ${pkgs.php}/bin/php maintenance/run.php update.php

      echo "Done."
    '';
  };
}
