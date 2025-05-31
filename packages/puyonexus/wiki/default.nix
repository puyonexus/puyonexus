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
      rev = "6ebcd929c7f7a2f8be715dfe39c59b53570829f0";
      hash = "sha256-Hs2p2lyp6NVFIk1Pk+AlyX8aCJ7AUNBJrZQ1G+tbOt4=";
    };
    cargo = mkWikimediaExtension {
      name = "Cargo";
      rev = "53883662f167216d493d11828618fb1a115c95ef";
      hash = "sha256-PU7TtJVBnBiBhWh0dBBULbCHWhxf4WJVboQb0xUJWUY=";
    };
    categoryTree = mkWikimediaExtension {
      name = "CategoryTree";
      rev = "577b42353f8201e5499e55cf91175293ee3c9ef7";
      hash = "sha256-S/Tz0wMS4qRUCoYov66ccr/+71/9iczAAP9XMd+0O1M=";
    };
    checkUser = mkWikimediaExtension {
      name = "CheckUser";
      rev = "9406c4c61802182ab253679b1c4812dcb372cff0";
      hash = "sha256-wbCdK3JX8c7e434nqyvoR4K9lrGa1QQshslne4dh+iY=";
    };
    cite = mkWikimediaExtension {
      name = "Cite";
      rev = "3966086815ff3cbb19f0bf47de37af1d1d4985f2";
      hash = "sha256-T5o6Wuf2lpczIGXwtB/jUSRJ4l2S4CuPBc8MexPwKjs=";
    };
    codeEditor = mkWikimediaExtension {
      name = "CodeEditor";
      rev = "627d1ac42e6daf18ba439812d5d5b38001db6d71";
      hash = "sha256-HPNGNgWhXvoNQz906Jlp12TmxRMhnv0GmpOpdx/NSlY=";
    };
    confirmEdit = mkWikimediaExtension {
      name = "ConfirmEdit";
      rev = "4787b2e4be1886ab077a01f9e7d81aa0b28ca7af";
      hash = "sha256-WMZiBqXDgVyeuwKRN1mEjbO6a8wCfaBV6ej3txquXJg=";
    };
    echo = mkWikimediaExtension {
      name = "Echo";
      rev = "951879a4181162f93b2d409a5374bce785eaf8f2";
      hash = "sha256-wtAdCyq/uStpp2W2AyPlbo4EmcPzklhSP//M1s4GjU8=";
    };
    embedVideo = mkExtension "EmbedVideo" (fetchFromGitHub {
      owner = "StarCitizenWiki";
      repo = "mediawiki-extensions-EmbedVideo";
      rev = "v3.4.3";
      hash = "sha256-GcEZA27eESfA4qmOPEAaGP1buzdo3iCj+wkUzLRFxmM=";
    });
    gadgets = mkWikimediaExtension {
      name = "Gadgets";
      rev = "94c0d38d5a5810b4cce22963a44aceb5e8dc1fd1";
      hash = "sha256-hxTB6xP5jxLF8frnZqtuz4Kt0r3V2KyebilNcMHMMn4=";
    };
    imageMap = mkWikimediaExtension {
      name = "ImageMap";
      rev = "1aa7ea696c546c716a9e6168bfd0edfa73c7ff29";
      hash = "sha256-KH59Sjth6T2e0OnA1bnwpn6G9ciemIIwSTviUvdC/Zo=";
    };
    inputBox = mkWikimediaExtension {
      name = "InputBox";
      rev = "a8184c4572811cf9df340702e882fe95baa885a0";
      hash = "sha256-FnXYjRSy3eFkC6g8GPgIzRzhBanwaW+bWWL3+3oZs90=";
    };
    math = mkWikimediaExtension {
      name = "Math";
      rev = "2360e60228dcac111f2063feb5104ab84878a898";
      hash = "sha256-xULflrWdTUvLOlLr5vlpw2lH6+Zt28It4SVAoJ3S+/k=";
    };
    moderation = mkExtension "Moderation" (fetchFromGitHub {
      owner = "edwardspec";
      repo = "mediawiki-moderation";
      rev = "v1.8.22";
      hash = "sha256-qaubRQlSxlPso5ZEOuGdEM1bGfbmdntW7B17jyvGmaI=";
    });
    msUpload = mkWikimediaExtension {
      name = "MsUpload";
      rev = "361dee8947892dd881ed427dc6040f0eb699c952";
      hash = "sha256-tEATieYjhipaknZ/1q7EIxtXOi1+ylVMVuOGr0i0F2I=";
    };
    nuke = mkWikimediaExtension {
      name = "Nuke";
      rev = "45f54278c22d5f6d7af8ed47f2e0517ee725d070";
      hash = "sha256-09SlJkg2bgYtv1CRsIJrqhgXWioiXPKiqkXfl2orAcg=";
    };
    parserFunctions = mkWikimediaExtension {
      name = "ParserFunctions";
      rev = "7199d854882d6e63ee9250f1ac8ef79188947465";
      hash = "sha256-iLbaoIyvufvTeLaDv6Brz1oknOTosSItppb+th/dSzU=";
    };
    poem = mkWikimediaExtension {
      name = "Poem";
      rev = "8c1e853e2e7f08d20e0c78309509c90b46f73bae";
      hash = "sha256-NBrVXeGSfvw9RSoZlEIUE1FBkQQQ9fMAKWD51ZTzVKw=";
    };
    puyoChain = mkExtension "PuyoChain" ./extensions/PuyoChain;
    renameuser = mkWikimediaExtension {
      name = "Renameuser";
      rev = "e7b2820bf74bbc6a6c0e0969b08bc30c039b1ab1";
      hash = "sha256-RAMIb5yHJ7JPpC0grQ8HTaOanaV/XafkRIbT6sC750g=";
    };
    replaceText = mkWikimediaExtension {
      name = "ReplaceText";
      rev = "f5d1655cb951c223b651b995026a1277a9f54687";
      hash = "sha256-/5bX3VHULfiP8FR6Ed5AD8i1pexqicl3O3XJaW9KtsY=";
    };
    scaledImage = mkExtension "ScaledImage" ./extensions/ScaledImage;
    spamBlacklist = mkWikimediaExtension {
      name = "SpamBlacklist";
      rev = "b7e906f612971a9de2c64eaeb5c2104b60fc6109";
      hash = "sha256-ZRGeu802j5tNRQ3eGIyipH75FxcafGcIxU0GnrogbUA=";
    };
    syntaxHighlight = mkWikimediaExtension {
      name = "SyntaxHighlight_GeSHi";
      rev = "c9db27e9a2ebda84c34093152b271bf5144ec26a";
      hash = "sha256-GWvznGIdIaOd7zGXm1hjunN2TLVJlx0+cknJDzCKlTY=";
    };
    tabberNeue = mkExtension "TabberNeue" (fetchFromGitHub {
      owner = "StarCitizenTools";
      repo = "mediawiki-extensions-TabberNeue";
      rev = "refs/tags/v3.0.0";
      hash = "sha256-oPd2Xl5BqHNjr9B6Idc8U8NxMNw7jBcXqBwRr3SRu5g=";
    });
    templateStyles = mkWikimediaExtension {
      name = "TemplateStyles";
      rev = "87f29540d1a04c8f727c7f6302ae504a990e8e69";
      hash = "sha256-TcyKOTPg6ZhuD5tr+Ep7VGjHL7jH0KNed11VRMlKT5w=";
    };
    thanks = mkWikimediaExtension {
      name = "Thanks";
      rev = "40a5ba7f417f895a14f5289ed87f01b28a390ecb";
      hash = "sha256-NF5ku8ZlgP1UM4moQK1Wu6UN//KWnweYXm0QE6QSir0=";
    };
    wikiEditor = mkWikimediaExtension {
      name = "WikiEditor";
      rev = "67f6158919d1d2e0de0a716c7cf4f7fbd240445a";
      hash = "sha256-5uH+xbE8PhDlW4Vzfp7F2Cni4Kx1bmmCFSddgcrPErM=";
    };
  };
  skin = {
    modern = mkWikimediaSkin {
      name = "Modern";
      rev = "eb6dc18880a3c6edda09de7ef5e5d71b2e3d0a8d";
      hash = "sha256-cvFPDxxTYNXLQk3OTAfHdb4LJ6dsRKK4Urzs0EcVVME=";
    };
    vector = mkWikimediaSkin {
      name = "Vector";
      rev = "a4a127342e106a27d89253921cc771a978523a68";
      hash = "sha256-78LGB3/7tPt+T92mLtRfg4gXA/s0aNtYGtuyKYLk944=";
    };
    vectorNexus = mkSkin "VectorNexus" (callPackage ./skins/VectorNexus/package.nix { });
    monoBook = mkWikimediaSkin {
      name = "MonoBook";
      rev = "4f2266626b36bb7556e54b87814b0016bd1adf2b";
      hash = "sha256-gw5WPzWY+Ws/9E7FXy8RQzqMc1I7OgtCTDNZ/RczExI=";
    };
    cologneBlue = mkWikimediaSkin {
      name = "CologneBlue";
      rev = "57a13971bebd561b0b6bb65ff0032fa11df6f71d";
      hash = "sha256-bDJj4Q45355y/Y9r0vADxNDPTlPgtUSfIaOIeZq1adU=";
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
  version = "1.43.1";

  src = stdenvNoCC.mkDerivation {
    name = "puyonexus-wiki-src";
    src = fetchFromGitHub {
      owner = "Wikimedia";
      repo = "mediawiki";
      rev = "1.43.1";
      hash = "sha256-LhUo/m8sgLFrSoX8LbsQEZawAiLzPKNjYR6HJSeS9hI=";
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
    vendorHash = "sha256-IR78W4125xC/kqXTCqB5bGTQO6SIMiS0j0bjP1acBHw=";
    composerLock = ./composer.lock;
    composerNoDev = true;
    composerNoPlugins = false;
    composerNoScripts = true;
    composerStrictValidation = true;
    dontCheckForBrokenSymlinks = false;
  };
})
