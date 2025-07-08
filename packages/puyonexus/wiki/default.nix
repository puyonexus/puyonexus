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
      rev = "53883662f167216d493d11828618fb1a115c95ef";
      hash = "sha256-PU7TtJVBnBiBhWh0dBBULbCHWhxf4WJVboQb0xUJWUY=";
    };
    checkUser = mkWikimediaExtension {
      name = "CheckUser";
      rev = "9406c4c61802182ab253679b1c4812dcb372cff0";
      hash = "sha256-wbCdK3JX8c7e434nqyvoR4K9lrGa1QQshslne4dh+iY=";
    };
    math = mkWikimediaExtension {
      name = "Math";
      rev = "2360e60228dcac111f2063feb5104ab84878a898";
      hash = "sha256-xULflrWdTUvLOlLr5vlpw2lH6+Zt28It4SVAoJ3S+/k=";
    };
    msUpload = mkWikimediaExtension {
      name = "MsUpload";
      rev = "361dee8947892dd881ed427dc6040f0eb699c952";
      hash = "sha256-tEATieYjhipaknZ/1q7EIxtXOi1+ylVMVuOGr0i0F2I=";
    };
    renameuser = mkWikimediaExtension {
      name = "Renameuser";
      rev = "e7b2820bf74bbc6a6c0e0969b08bc30c039b1ab1";
      hash = "sha256-RAMIb5yHJ7JPpC0grQ8HTaOanaV/XafkRIbT6sC750g=";
    };
    templateStyles = mkWikimediaExtension {
      name = "TemplateStyles";
      rev = "87f29540d1a04c8f727c7f6302ae504a990e8e69";
      hash = "sha256-TcyKOTPg6ZhuD5tr+Ep7VGjHL7jH0KNed11VRMlKT5w=";
    };

    # Third-party extensions
    embedVideo = mkExtension "EmbedVideo" (fetchFromGitHub {
      owner = "StarCitizenWiki";
      repo = "mediawiki-extensions-EmbedVideo";
      rev = "v3.4.3";
      hash = "sha256-GcEZA27eESfA4qmOPEAaGP1buzdo3iCj+wkUzLRFxmM=";
    });
    moderation = mkExtension "Moderation" (fetchFromGitHub {
      owner = "edwardspec";
      repo = "mediawiki-moderation";
      rev = "v1.8.31";
      hash = "sha256-I75ssZi8uqlCxKZRVhH9o1C5GDiTFeGaOpXApnYuzPc=";
    });
    tabberNeue = mkExtension "TabberNeue" (fetchFromGitHub {
      owner = "StarCitizenTools";
      repo = "mediawiki-extensions-TabberNeue";
      rev = "refs/tags/v3.1.2";
      hash = "sha256-jyDlbILh40Xj/ZKXc83BsnV5lFQ8SCZv4pvN2l2uW4M=";
    });

    # Puyo Nexus extensions
    puyoChain = mkExtension "PuyoChain" ./extensions/PuyoChain;
    scaledImage = mkExtension "ScaledImage" ./extensions/ScaledImage;
  };
  skin = {
    #
    modern = mkWikimediaSkin {
      name = "Modern";
      rev = "eb6dc18880a3c6edda09de7ef5e5d71b2e3d0a8d";
      hash = "sha256-cvFPDxxTYNXLQk3OTAfHdb4LJ6dsRKK4Urzs0EcVVME=";
    };
    cologneBlue = mkWikimediaSkin {
      name = "CologneBlue";
      rev = "57a13971bebd561b0b6bb65ff0032fa11df6f71d";
      hash = "sha256-bDJj4Q45355y/Y9r0vADxNDPTlPgtUSfIaOIeZq1adU=";
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
  version = "1.43.3";

  src = stdenvNoCC.mkDerivation {
    name = "puyonexus-wiki-src";
    src = fetchFromGitHub {
      owner = "Wikimedia";
      repo = "mediawiki";
      rev = "refs/tags/1.43.3";
      hash = "sha256-lNFJPuev5JdttyTkzt9NK+Yt6Z5+5g1mTnWVhGt+aak=";
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
    vendorHash = "sha256-uN3Zjqykg3BKE+KdhwaWXsrkmehczQIEaGSBczHznmY=";
    composerLock = ./composer.lock;
    composerNoDev = true;
    composerNoPlugins = false;
    composerNoScripts = true;
    composerStrictValidation = true;
    dontCheckForBrokenSymlinks = false;
  };
})
