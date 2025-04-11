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
    abuseFilter = mkWikimediaExtension {
      name = "AbuseFilter";
      rev = "741d83bbb693261d68bd3e54ad83ec9a51e45c32";
      hash = "sha256-2SUalWDI25QBOZ47/hfBaolCFohepJRXxiStc++2SDg=";
    };
    cargo = mkWikimediaExtension {
      name = "Cargo";
      rev = "19ab7cbac964728c575bd4ebb75f700f7b633c30";
      hash = "sha256-965B6IAuTHEj/oVaUik7oO4fq+OLiRtSOdPOfCAqCh4=";
    };
    categoryTree = mkWikimediaExtension {
      name = "CategoryTree";
      rev = "312e5b12347a1d83a738be19cbc153d3e8f780b5";
      hash = "sha256-xOW2LxfduyVQZqTIqf0niR5G/MjM12kaUTK3Pd+EufY=";
    };
    checkUser = mkWikimediaExtension {
      name = "CheckUser";
      rev = "3a20e8a0c5f9749f9c7b983088d2cb4a2847c001";
      hash = "sha256-L0rzT5A8rGHQ4NEFLe7jbH66qsXpCNlGprNc71RHV2Q=";
    };
    cite = mkWikimediaExtension {
      name = "Cite";
      rev = "fd6a69c68a8273f2651ed7a3cebb94df8b13ad18";
      hash = "sha256-6J6rXj/YctTQdGTNkV/QxJHrE0wb0pphA19IWwp3DRE=";
    };
    codeEditor = mkWikimediaExtension {
      name = "CodeEditor";
      rev = "28fd08b1ef466e33b435d5aba9211470680f9d01";
      hash = "sha256-lUeXcH9k1sfZYDmhTSrJBB6Y+ObRgJpeyQigeTaHHB4=";
    };
    confirmEdit = mkWikimediaExtension {
      name = "ConfirmEdit";
      rev = "1513e74d894d04d20a1d9bc6fcff5d56bb63b1e2";
      hash = "sha256-WlDwg1f0N6d2GIUoctqMdxqAmze6D0Bu19YeN1Iwj6c=";
    };
    echo = mkWikimediaExtension {
      name = "Echo";
      rev = "25521c5fc752d0d08f2e22a3d2d0a526dd2fffaf";
      hash = "sha256-xNHlXjPAF18NQMGykS8BeOPu+5lrCMI9nSaA3kmmTV0=";
    };
    embedVideo = mkExtension "EmbedVideo" (fetchFromGitHub {
      owner = "StarCitizenWiki";
      repo = "mediawiki-extensions-EmbedVideo";
      rev = "v3.4.3";
      hash = "sha256-GcEZA27eESfA4qmOPEAaGP1buzdo3iCj+wkUzLRFxmM=";
    });
    gadgets = mkWikimediaExtension {
      name = "Gadgets";
      rev = "d953121a2d649cb5bbffce22294f404caafc1508";
      hash = "sha256-3DH/P7HyEWzWb+O5UOSOCXQ4lzcM4Xmpr/o2sHDfosI=";
    };
    imageMap = mkWikimediaExtension {
      name = "ImageMap";
      rev = "727266f88cd580f5f8b39937299fb263f3f8d1c6";
      hash = "sha256-92VWJ23w1EMkUe1KfEESGNWm5gGMm7683qguPIswnf8=";
    };
    inputBox = mkWikimediaExtension {
      name = "InputBox";
      rev = "0d97c546b1a7a15daadf069670ee1416a88e56e3";
      hash = "sha256-PbvdBJFdGW32ITpnsXtNusZWM31dN2XX0v/gsVBS9fo=";
    };
    math = mkWikimediaExtension {
      name = "Math";
      rev = "fe886ea3e989ec1aa0488396c1fe463882804b94";
      hash = "sha256-7ANfPks1PrS2ltUYYdS4JAZqpewLrblIpxOM9o6T/uw=";
    };
    moderation = mkExtension "Moderation" (fetchFromGitHub {
      owner = "edwardspec";
      repo = "mediawiki-moderation";
      rev = "v1.8.22";
      hash = "sha256-qaubRQlSxlPso5ZEOuGdEM1bGfbmdntW7B17jyvGmaI=";
    });
    msUpload = mkWikimediaExtension {
      name = "MsUpload";
      rev = "c80f7fb08ae7330c641292dee7479ff0d4b2f032";
      hash = "sha256-0GlOO75b7pP0k+FBrPx//ksP/EAT+5utD8gcwhu+M9Q=";
    };
    nuke = mkWikimediaExtension {
      name = "Nuke";
      rev = "b52860fad87a49cf181c840f5c9be76b809850c4";
      hash = "sha256-pPjdvoKFBkRWlec19XBjEINaoc5sXhK30XvH55EXfm4=";
    };
    parserFunctions = mkWikimediaExtension {
      name = "ParserFunctions";
      rev = "20be20185a965fbe86f7b2d40c0ae0602e516ae9";
      hash = "sha256-lHOe5S+khbIdDWC2PGAJT7BK0lrXiIpob6Kq6ujQYig=";
    };
    poem = mkWikimediaExtension {
      name = "Poem";
      rev = "d28b949f1aadbb53ea96f66b7b73240c1ecdfd74";
      hash = "sha256-Z/UqEL2Hr2Zrga9P2AHqkuQVXUKd57uMe9x1LfefIS8=";
    };
    puyoChain = mkExtension "PuyoChain" ./extensions/PuyoChain;
    renameuser = mkWikimediaExtension {
      name = "Renameuser";
      rev = "d6a42621e8612f0dd15d608ec6140ff33d067ef0";
      hash = "sha256-u8cz81K7d/XMrat8bA0U4hPZ4cm7/4bh92ZIXV0bzdw=";
    };
    replaceText = mkWikimediaExtension {
      name = "ReplaceText";
      rev = "5fad974a9bdb9bd130ceec9c8ea0883ccf99fb50";
      hash = "sha256-0psII8MVy3bp4ZlKhYIANYPMgU10eYvF74rrxCMfNeI=";
    };
    scaledImage = mkExtension "ScaledImage" ./extensions/ScaledImage;
    spamBlacklist = mkWikimediaExtension {
      name = "SpamBlacklist";
      rev = "46c979dfca23e1c8219cf888ebebcb6544455f45";
      hash = "sha256-u3ombB1kQyE/pLtJukTMfAeM/z+IKY9TrHUJfFobZ6E=";
    };
    syntaxHighlight = mkWikimediaExtension {
      name = "SyntaxHighlight_GeSHi";
      rev = "2e8fb3c42db2d04518afd37c1fe14ee251df2b75";
      hash = "sha256-BsL04ep9TyR84NYMueu+am6CRHIhCIxPUcrmwtIg4uQ=";
    };
    templateStyles = mkWikimediaExtension {
      name = "TemplateStyles";
      rev = "06c1e6fc12ac9ba16a755bc62d621e922b8ffda8";
      hash = "sha256-zzKvUJTaoT2yK4KmZMGa8M9m6JZJfjQmEzl+xotaF/g=";
    };
    thanks = mkWikimediaExtension {
      name = "Thanks";
      rev = "797242234aa45b5589f8b2ca928299bb8a8e05f5";
      hash = "sha256-pB3Y/j9sk0Prsbm7HAD76kspR1+k7PpBfqcQ4iVIkBM=";
    };
    wikiEditor = mkWikimediaExtension {
      name = "WikiEditor";
      rev = "600f790ba8f31469fe71b6e24c1ea078b96ea398";
      hash = "sha256-mcsP8f+NgX2LkxdMUTmul+pNL7eVlzPcmzrUCwSOPZU=";
    };
  };
  skin = {
    modern = mkWikimediaSkin {
      name = "Modern";
      rev = "2c6912723fe21772ce564e526417976fb8316c47";
      hash = "sha256-pGENIuCAalEi7J0tfjdQfvMSSdPFe3HCqBE0nx6n9/Y=";
    };
    vector = mkWikimediaSkin {
      name = "Vector";
      rev = "8cba83e9d342902f20f40db7cf0397891c0abbd5";
      hash = "sha256-MD5izSINzkQw8OOwovHfDUDcag74w4kmCs/vwWFGlK0=";
    };
    vectorNexus = mkSkin "VectorNexus" (callPackage ./skins/VectorNexus/package.nix { });
    monoBook = mkWikimediaSkin {
      name = "MonoBook";
      rev = "b583f5fddcac4fae765337d41956511135e7c88c";
      hash = "sha256-Tt7NoSbhk0GeUq0NF26z4ogHo5pnDiKcMjeYQBLiyhM=";
    };
    cologneBlue = mkWikimediaSkin {
      name = "CologneBlue";
      rev = "0a46bea23349cfd1136096550246334bd4584de3";
      hash = "sha256-K4cboePaRjWjEyG76PVYllKmQNhXKTFNyJTo/H+FcW0=";
    };
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
  version = "1.42.6";

  src = stdenvNoCC.mkDerivation {
    name = "puyonexus-wiki-src";
    src = fetchFromGitHub {
      owner = "Wikimedia";
      repo = "mediawiki";
      rev = "1.42.6";
      hash = "sha256-gyL/ljMKxZtXI5ukcZe2YXTUK9NFvjjvyMHMwMriQaU=";
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

  composerVendor =
    php.mkComposerVendor {
      inherit (finalAttrs)
        pname
        src
        version
        ;
      vendorHash = "sha256-FgxhXanwur+INHCuX6TM7FO/3Xywa3EJcim5u6VwnyE=";
      composerLock = ./composer.lock;
      composerNoDev = true;
      composerNoPlugins = false;
      composerNoScripts = true;
      composerStrictValidation = true;
      dontCheckForBrokenSymlinks = false;
    };
})
