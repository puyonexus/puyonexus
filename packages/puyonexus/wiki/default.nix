{
  stdenvNoCC,
  fetchFromGitHub,
  lib,
  writeText,
  php,
  callPackage,
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
      rev = "62ed8bc1cd1db365830513298514e01a252687b6";
      hash = "sha256-EnhaKMz/Hvo6gYb0Ji7n+gv9aIO0X+gweS6lTUes4Jc=";
    };
    checkUser = mkWikimediaExtension {
      name = "CheckUser";
      rev = "43d777d0a8334eaff31994b92f4290efc50fc5df";
      hash = "sha256-H1HXCUzSdsuyttvwGTMIiaimRQtcGsW1CGco4UnW8i8=";
    };
    cite = mkWikimediaExtension {
      name = "Cite";
      rev = "c5b39084ea772cf80d9d25e7e590a1aa63ac7676";
      hash = "sha256-bZCBeUKFZkTnb9/RXYHKFP1KKYE/YGMDbwQAIR7dTKc=";
    };
    codeEditor = mkWikimediaExtension {
      name = "CodeEditor";
      rev = "549934791b8be819921e4d7910830dbd70c5f788";
      hash = "sha256-5ubdgGlLzNgNLUTvzO8XiNKco5qTY2Jv+i0364wTbGo=";
    };
    confirmEdit = mkWikimediaExtension {
      name = "ConfirmEdit";
      rev = "48757725a81a500c5121517ea7c72c6926279718";
      hash = "sha256-MTv3OGxnemWYNSHCov8XdYVmKui3q3rMDsgdvRYqwsg=";
    };
    embedVideo = mkExtension "EmbedVideo" (fetchFromGitHub {
      owner = "StarCitizenWiki";
      repo = "mediawiki-extensions-EmbedVideo";
      rev = "v3.4.2";
      hash = "sha256-GN6Lhf0mcyzLDLzn8UhxLCdLH7sYtzVuOIbCBMK8wj0=";
    });
    gadgets = mkWikimediaExtension {
      name = "Gadgets";
      rev = "3f446f9c46822edfacf93ff15afb4670a5ce6687";
      hash = "sha256-HEogi28zYg3fYT5hkK4mRhsBU3bu8nC07ME1Rs69bAE=";
    };
    imageMap = mkWikimediaExtension {
      name = "ImageMap";
      rev = "832faa7c7a945d318312dfcc6c0174767cc5a50c";
      hash = "sha256-oSaalATJCzsRiNM2x/lVH1owhgu8/fxhV3efuur6gRY=";
    };
    inputBox = mkWikimediaExtension {
      name = "InputBox";
      rev = "b780b8e31b8537a3598eeea9b1efb20a40813e67";
      hash = "sha256-A1+5dAazhAiOdyly+P/AUFWbcu57iyKFTlyHb8RnMEY=";
    };
    math = mkWikimediaExtension {
      name = "Math";
      rev = "8a0bc1400e4a75e3853e2787037927316800ec8e";
      hash = "sha256-DS3vhpwgEZ4H0aKSknN7QPf/z5I+2g4cx4zrB1ZEKvQ=";
    };
    moderation = mkExtension "Moderation" (fetchFromGitHub {
      owner = "edwardspec";
      repo = "mediawiki-moderation";
      rev = "v1.8.9";
      hash = "sha256-aZZUlFqh831A+ICXh8VzvEHcafG+vCNo3hE267EyG08=";
    });
    msUpload = mkWikimediaExtension {
      name = "MsUpload";
      rev = "e8c2f23c46dfb56123115e1570485cee5b22edde";
      hash = "sha256-d/aioNxoKdDfwJZN11MaSw5Sa+8T5dP8U4wWnf7+50s=";
    };
    nuke = mkWikimediaExtension {
      name = "Nuke";
      rev = "54a2121e0855e445c32f3b9630e4410e53536bf6";
      hash = "sha256-88oMvnyhNofm0+19TSu9YwUpXQfb2cPgbb6jDUngLTQ=";
    };
    parserFunctions = mkWikimediaExtension {
      name = "ParserFunctions";
      rev = "ef17499879101f3100c214a3f9d696dc00570165";
      hash = "sha256-2phLFNAtB8p8nsaXxw9dsQb6z1bKQuOavTsf/5UkVRo=";
    };
    poem = mkWikimediaExtension {
      name = "Poem";
      rev = "f18362eb6d4ca1aaa0a9cc528d483c9217d82c16";
      hash = "sha256-BrNbD1jQPm/ec8tR3Li++olZgI6LwZVc0NIPGlo8nCw=";
    };
    puyoChain = mkExtension "PuyoChain" ./extensions/PuyoChain;
    renameuser = mkWikimediaExtension {
      name = "Renameuser";
      rev = "f1687b749a8af6c91596ca25325fa4264e43bbae";
      hash = "sha256-BnzHwxmvLOf+9vkX2zEiR78coeoYxS8SwdWv/9kb7kw=";
    };
    replaceText = mkWikimediaExtension {
      name = "ReplaceText";
      rev = "3450fd0f3209441213eb7924a1a35378a86d6f9a";
      hash = "sha256-ClVPXS24KvJCqSL5a3yCZyRkDHt7TYKwFKQggTCy8wc=";
    };
    scaledImage = mkExtension "ScaledImage" ./extensions/ScaledImage;
    spamBlacklist = mkWikimediaExtension {
      name = "SpamBlacklist";
      rev = "6f3fc80fcbd7406b8e451df96bc04f0a1f722541";
      hash = "sha256-I+KQmeNNDondsd2Mtquow5jP4wJGfV0LR9kCBJLrefM=";
    };
    syntaxHighlight = mkWikimediaExtension {
      name = "SyntaxHighlight_GeSHi";
      rev = "e4fabbb7b4665e6066e931c5c48f39e0774c803a";
      hash = "sha256-B9AwpXZBSI5gQgv8b3m6rxPng2ajXMPTO5l7OPE3bII=";
    };
    templateStyles = mkWikimediaExtension {
      name = "TemplateStyles";
      rev = "8cb3a92f8b963ed317f5645d737dbed4df404e62";
      hash = "sha256-T6IumsUW4nI79puZDifbAadd7YMkeGwVYmUdMtuELoY=";
    };
    wikiEditor = mkWikimediaExtension {
      name = "WikiEditor";
      rev = "4859a5ed5e77965cdee1f489940fe6440306e273";
      hash = "sha256-qEdw9cE21QRwB6gbmC1UwEYBuMHOErA58tDWxE1yfX0=";
    };
  };
  skin = {
    modern = mkWikimediaSkin {
      name = "Modern";
      rev = "2a237ea7e4f49961b2492b66dfd3faba8d787253";
      hash = "sha256-IZDWEOjkRqfZFkscAkjS02AkAj71wnCHkcMDVH32IPM=";
    };
    vector = mkWikimediaSkin {
      name = "Vector";
      rev = "02287c6b1cf9dfc0f391bd00e0bb481d3691adc5";
      hash = "sha256-uKaOyU+33XAyBjVlZ5cUH+9INhpLuMn5hLUZ2uXsKS0=";
    };
    vectorNexus = mkSkin "VectorNexus" (callPackage ./skins/VectorNexus/package.nix { });
    monoBook = mkWikimediaSkin {
      name = "MonoBook";
      rev = "6b1adf8a5950102f19ca2125d6437843d669175c";
      hash = "sha256-IwKQHV8Q6Mx1zmdoayOgcW9NQgAudC+tfuqwN3Q3PV0=";
    };
    cologneBlue = mkWikimediaSkin {
      name = "CologneBlue";
      rev = "dd4645e47a8b199ae98e46a3e3a3469bb9d14012";
      hash = "sha256-7PCyy8KZ149Wa0x5woO0uWwvyaTOJkdcFFmCXIKIKjY=";
    };
  };
in
php.buildComposerProject (finalAttrs: {
  pname = "puyonexus-wiki";
  version = "1.42.1";

  src = fetchFromGitHub {
    owner = "Wikimedia";
    repo = "mediawiki";
    rev = "1.42.1";
    hash = "sha256-tkVyhAHxYuikfy+HLcIYbsWII3+S67XZzwnnBVMEZSs=";
  };

  patchPhase = ''
    runHook prePatch

    for component in $extensions $skins;
    do
      cp -R $component/. .
    done;
    cp ${writeText "LocalSettings.php" finalAttrs.localSettings} LocalSettings.php
    cp ${./composer.local.json} composer.local.json

    runHook postPatch
  '';

  vendorHash = "sha256-d7NsCIQXcAotGVHKzIJ8TLf5yJjLW8Ox74jQs8NI+2A=";
  composerLock = ./composer.lock;

  composerRepository = php.mkComposerRepository {
    inherit (finalAttrs)
      pname
      src
      patchPhase
      composerLock
      vendorHash
      version
      extensions
      skins
      ;
    composerNoDev = true;
    composerNoPlugins = false;
    composerNoScripts = true;
    composerStrictValidation = true;
  };

  extensions = [
    ext.abuseFilter
    ext.checkUser
    ext.cite
    ext.codeEditor
    ext.confirmEdit
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
      loadExts = lib.strings.concatMapStringsSep "\n" loadExt finalAttrs.extensions;
      loadSkins = lib.strings.concatMapStringsSep "\n" loadSkin finalAttrs.skins;
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
})
