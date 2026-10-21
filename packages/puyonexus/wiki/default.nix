{
  stdenvNoCC,
  fetchFromGitHub,
  lib,
  writeText,
  php,
  callPackage,
  jq,
}:
let
  wikimedia = import ./hashes.nix;
  fetchWikimediaModule =
    {
      name,
      type,
      rev,
      hash,
    }:
    fetchFromGitHub {
      inherit rev hash;
      owner = "Wikimedia";
      repo = "mediawiki-${type}-${name}";
    };
  fetchWikimediaExtension =
    {
      name,
      rev,
      hash,
    }:
    fetchWikimediaModule {
      inherit name rev hash;
      type = "extensions";
    };
  fetchWikimediaSkin =
    {
      name,
      rev,
      hash,
    }:
    fetchWikimediaModule {
      inherit name rev hash;
      type = "skins";
    };
  mkExtension =
    name: src:
    stdenvNoCC.mkDerivation {
      name = "mediawiki-extensions-${name}";
      inherit src;
      buildPhase = "true";
      installPhase = ''
        mkdir -p $out/extensions/${name}
        cp -R . $out/extensions/${name}
      '';
    };
  mkSkin =
    name: src:
    stdenvNoCC.mkDerivation {
      name = "mediawiki-skins-${name}";
      inherit src;
      buildPhase = "true";
      installPhase = ''
        mkdir -p $out/skins/${name}
        cp -R . $out/skins/${name}
      '';
    };
  mkWikimediaExtension = { name, ... }@inputs: mkExtension name (fetchWikimediaExtension inputs);
  mkWikimediaSkin = { name, ... }@inputs: mkSkin name (fetchWikimediaSkin inputs);
  ext = {
    # Bundled extensions
    abuseFilter = mkWikimediaExtension wikimedia.extensions.AbuseFilter;
    categoryTree = mkWikimediaExtension wikimedia.extensions.CategoryTree;
    cite = mkWikimediaExtension wikimedia.extensions.Cite;
    codeEditor = mkWikimediaExtension wikimedia.extensions.CodeEditor;
    confirmEdit = mkWikimediaExtension wikimedia.extensions.ConfirmEdit;
    echo = mkWikimediaExtension wikimedia.extensions.Echo;
    gadgets = mkWikimediaExtension wikimedia.extensions.Gadgets;
    imageMap = mkWikimediaExtension wikimedia.extensions.ImageMap;
    inputBox = mkWikimediaExtension wikimedia.extensions.InputBox;
    nuke = mkWikimediaExtension wikimedia.extensions.Nuke;
    parserFunctions = mkWikimediaExtension wikimedia.extensions.ParserFunctions;
    poem = mkWikimediaExtension wikimedia.extensions.Poem;
    replaceText = mkWikimediaExtension wikimedia.extensions.ReplaceText;
    spamBlacklist = mkWikimediaExtension wikimedia.extensions.SpamBlacklist;
    syntaxHighlight = mkWikimediaExtension wikimedia.extensions.SyntaxHighlight_GeSHi;
    thanks = mkWikimediaExtension wikimedia.extensions.Thanks;
    wikiEditor = mkWikimediaExtension wikimedia.extensions.WikiEditor;

    # Unbundled Wikimedia extensions
    cargo = mkWikimediaExtension {
      name = "Cargo";
      rev = "de2e27a2535d0c1ec98fab0b0757beb4622fe9d0";
      hash = "sha256-tJemViS3aiI1oq738FzdBrJ7EN29z4SIyKFkap+CSF8=";
    };
    checkUser = mkWikimediaExtension {
      name = "CheckUser";
      rev = "9d7c1d311e0ff2687498215c72bcc3e82cf8c90e";
      hash = "sha256-StjiqUwD/FsYS6B2+cRO0InjysKUXpeY7FeC2KU1UzY=";
    };
    math = mkWikimediaExtension {
      name = "Math";
      rev = "7f5cd1a4800f8b9a0ecd16de3175e5fdf83f4f03";
      hash = "sha256-xNDwfnKmJyof8tcxuR2kcBV7axSTPE+3WDWpmyuVN+k=";
    };
    msUpload = mkWikimediaExtension {
      name = "MsUpload";
      rev = "d0d145f4ed79e4f6f6e9a41a87145a41cb1517f3";
      hash = "sha256-yuDXPVXGVTGZo+qUaLpL8XTWSOMwqXmIBtp9d+ORK+A=";
    };
    renameuser = mkWikimediaExtension {
      name = "Renameuser";
      rev = "9c1b65e8ee99e04c3f36227015cef3fc2d4b6959";
      hash = "sha256-MJ1tp2bcVMHbjsbFmuClyPLXB9rp3oG2ADMtQID3MzA=";
    };
    templateStyles = mkWikimediaExtension {
      name = "TemplateStyles";
      rev = "e74200b2bcc2d5b36c1b0c02086c2907caa49eb1";
      hash = "sha256-qzJjFMTb0PtdVO5tWaqfsZB6gJndrje4PFqYE6Mg7Gs=";
    };

    # Third-party extensions
    embedVideo = mkExtension "EmbedVideo" (fetchFromGitHub {
      owner = "StarCitizenWiki";
      repo = "mediawiki-extensions-EmbedVideo";
      rev = "d0aa2a3245c1308362b2ce77df1f6bb3e2bf6579";
      hash = "sha256-l/npA13t/mKfKd5VooRqYcblbWqWeHFNo8isRp/NDn8=";
    });
    moderation = mkExtension "Moderation" (fetchFromGitHub {
      owner = "edwardspec";
      repo = "mediawiki-moderation";
      rev = "f0d423d11eb954ed7429d7618c1868303a5a5832";
      hash = "sha256-LrXtMvqWsnILhq+Z+BrAV5dUUtImSPqjPK/GU/M2CTU=";
    });
    tabberNeue = mkExtension "TabberNeue" (fetchFromGitHub {
      owner = "StarCitizenTools";
      repo = "mediawiki-extensions-TabberNeue";
      rev = "cbdb62ba4b45c3060aa27001a0519e16cdc63523";
      hash = "sha256-ZC/Z9Ktq/1vvxsEhzqbn3/KoBANCvZU0HJY0jH1J1HE=";
    });

    # Puyo Nexus extensions
    puyoChain = mkExtension "PuyoChain" ./extensions/PuyoChain;
    scaledImage = mkExtension "ScaledImage" ./extensions/ScaledImage;
  };
  skin = {
    #
    modern = mkWikimediaSkin {
      name = "Modern";
      rev = "9504bc2fa08f423a47fcee3e1da365a3b8b7a5a2";
      hash = "sha256-mW+ESISEoKAV9BjkeGZfEcjW9LE1iEg4n1aVTezoRCc=";
    };
    cologneBlue = mkWikimediaSkin {
      name = "CologneBlue";
      rev = "a2419bb88ecf589dcfd18462c58fc764e4d3c2dc";
      hash = "sha256-WigDK4KQpzH2VSUAHgtAbP3V66AjT6CkHsH9TI3mWFM=";
    };
    vector = mkWikimediaSkin wikimedia.skins.Vector;
    monoBook = mkWikimediaSkin wikimedia.skins.MonoBook;
    vectorNexus = mkSkin "VectorNexus" (
      callPackage ./skins/VectorNexus/package.nix {
        vector = fetchWikimediaSkin wikimedia.skins.Vector;
      }
    );
  };
  extensions = [
    ext.abuseFilter
    ext.cargo
    ext.categoryTree
    ext.checkUser
    ext.cite
    ext.codeEditor
    ext.confirmEdit
    ext.echo
    ext.embedVideo
    ext.gadgets
    ext.imageMap
    ext.inputBox
    ext.math
    ext.moderation
    ext.msUpload
    ext.nuke
    ext.parserFunctions
    ext.poem
    ext.puyoChain
    ext.renameuser
    ext.replaceText
    ext.scaledImage
    ext.spamBlacklist
    ext.syntaxHighlight
    ext.tabberNeue
    ext.templateStyles
    ext.thanks
    ext.wikiEditor
  ];
  skins = [
    skin.modern
    skin.vector
    skin.vectorNexus
    skin.monoBook
    skin.cologneBlue
  ];
  localSettings =
    let
      extName = ext: lib.strings.removePrefix "mediawiki-extensions-" ext.name;
      skinName = skin: lib.strings.removePrefix "mediawiki-skins-" skin.name;
      loadExt = ext: "wfLoadExtension('${extName ext}');";
      loadSkin = skin: "wfLoadSkin('${skinName skin}');";
      loadExts = lib.strings.concatMapStringsSep "\n" loadExt extensions;
      loadSkins = lib.strings.concatMapStringsSep "\n" loadSkin skins;
    in
    ''
      <?php
      if (!defined('MEDIAWIKI')) { exit; }

      require_once(getenv('PUYONEXUS_WIKI_LOCALSETTINGS_PATH'));

      # Extensions
      ${loadExts}

      # Skins
      ${loadSkins}

      # This hack is needed because MediaWiki is stubborn.
      # Putting it in the body results in flickering.
      # Putting it in resource loader is inconvenient.
      $wgHooks['BeforePageDisplay'][] = function(MediaWiki\Output\OutputPage $out, Skin $skin) {
        if ($skin->getSkinName() == "vectornexus") {
          $out->addStyle('/assets/css/common.css', 'screen');
        }
      };
    '';
in
php.buildComposerProject2 (finalAttrs: {
  pname = "puyonexus-wiki";
  version = "1.43.11";

  src = stdenvNoCC.mkDerivation {
    name = "puyonexus-wiki-src";
    src = fetchFromGitHub {
      owner = "Wikimedia";
      repo = "mediawiki";
      rev = "8c65f3e15450df456092626693350a8c729bd003";
      hash = "sha256-USGjzI+YFMAOPcWbWq/9dMcUYKBvbfCgCAz42WwZ7xo=";
    };
    buildPhase = "true";
    installPhase = ''
      mkdir -p $out
      cp -R . $out
      cd $out
      for component in ${toString extensions} ${toString skins};
      do
        cp -R $component/. .
      done;
      cp ${writeText "LocalSettings.php" localSettings} LocalSettings.php
      ${lib.getExe jq} -rs '.[0] * {require: (reduce .[] as $item ({}; . + ($item.require // {})))}' composer.json extensions/*/composer.json skins/*/composer.json > composer.local.json
      mv composer.local.json composer.json
    '';
  };

  composerVendor = php.mkComposerVendor {
    inherit (finalAttrs)
      pname
      src
      version
      ;
    vendorHash = "sha256-evTUcBiidzgL4YMdvAr+w2dLCLc+O3bVb2wpaKmYfXs=";
    composerLock = ./composer.lock;
    composerNoDev = true;
    composerNoPlugins = false;
    composerNoScripts = true;
    composerStrictValidation = true;
    dontCheckForBrokenSymlinks = false;
  };
})
