{
  stdenv,
  stdenvNoCC,
  fetchgit,
  fetchFromGitHub,
  lib,
  writeText,
  php,
  callPackage,
}:
let
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
  ext = {
    abuseFilter = mkExtension "AbuseFilter" (fetchgit {
      url = "https://gerrit.wikimedia.org/r/mediawiki/extensions/AbuseFilter";
      rev = "28974e0fde8164d9736cb95e649cd82551e6e3ae";
      hash = "sha256-2CDw1GA7Bgq4mV7ibHslqHP7bYYIvg7Ny2l/UknQNUI=";
    });
    checkUser = mkExtension "CheckUser" (fetchgit {
      url = "https://gerrit.wikimedia.org/r/mediawiki/extensions/CheckUser";
      rev = "aed89d030bb486fdcfc9a92a03ed94fb214493a9";
      hash = "sha256-D7E+K9losMdpli0mlqvYubL+s2IWxHFDyU+ommwUwA0=";
    });
    cite = mkExtension "Cite" (fetchgit {
      url = "https://gerrit.wikimedia.org/r/mediawiki/extensions/Cite";
      rev = "8f92b061f40994867adc8d82b1ee4e4bd12fb7ba";
      hash = "sha256-FLoUOs2ig084SpOFp+GZm2ZcWP8XX7H4RyltF3Es6Jw=";
    });
    confirmEdit = mkExtension "ConfirmEdit" (fetchgit {
      url = "https://gerrit.wikimedia.org/r/mediawiki/extensions/ConfirmEdit";
      rev = "20938e8360e292ded629d75ffaeed74798f14d37";
      hash = "sha256-ERZiRhb8BtQheoWhIMIBKtZjKzRgTLzNwfWAxXFBo/E=";
    });
    gadgets = mkExtension "Gadgets" (fetchgit {
      url = "https://gerrit.wikimedia.org/r/mediawiki/extensions/Gadgets";
      rev = "f2af97bee7534f17438af516c50a8b1033190f08";
      hash = "sha256-Dkh9B6EkrMeqWZDbm6m63ALRNIzYO4RCarUnxPzRro8=";
    });
    imageMap = mkExtension "ImageMap" (fetchgit {
      url = "https://gerrit.wikimedia.org/r/mediawiki/extensions/ImageMap";
      rev = "142a3cec750f68b972fe31d38009e9edec91b4bb";
      hash = "sha256-Lqt+GiHUiEy1xX1BAkXd1iTExD1ofwCjJkdkgrKQLj0=";
    });
    inputBox = mkExtension "InputBox" (fetchgit {
      url = "https://gerrit.wikimedia.org/r/mediawiki/extensions/InputBox";
      rev = "ffb574e0209eb499eea30cdc251e6490227154ee";
      hash = "sha256-KJOMg41/tQzD2y1af2lOKvO7lgp4FcGWb3PFYFsVphM=";
    });
    math = mkExtension "Math" (fetchgit {
      url = "https://gerrit.wikimedia.org/r/mediawiki/extensions/Math";
      rev = "bf859f07d0396b80094f0adada2b04fbf0616e37";
      hash = "sha256-9PjJO4aIg5f/bPBNIXR7C9ffHRLke9qYGkvbmBUYiWg=";
    });
    moderation = mkExtension "Moderation" (fetchFromGitHub {
      owner = "edwardspec";
      repo = "mediawiki-moderation";
      rev = "v1.7.9";
      hash = "sha256-cjMgGyT9XhlGqiQ80FN5/+RaWVlTEjTsHiww+Ux1EyU=";
    });
    msUpload = mkExtension "MsUpload" (fetchgit {
      url = "https://gerrit.wikimedia.org/r/mediawiki/extensions/MsUpload";
      rev = "19fba31cc448cf636b404e4ae9fb21d84b1ae430";
      hash = "sha256-6R4oHhHrVYQOxPtyNxB6sNc54LDarcnX7SPexX2DgF0=";
    });
    nuke = mkExtension "Nuke" (fetchgit {
      url = "https://gerrit.wikimedia.org/r/mediawiki/extensions/Nuke";
      rev = "9b99b4108134ca44f8eb2b797cea352ea89fd213";
      hash = "sha256-bK6Y7X7epP9Tbsk4RFG2BQz9ErVlyOyDVyvWBLys1Yk=";
    });
    parserFunctions = mkExtension "ParserFunctions" (fetchgit {
      url = "https://gerrit.wikimedia.org/r/mediawiki/extensions/ParserFunctions";
      rev = "47229c60a1e2b26361847735d945468c6c4372a8";
      hash = "sha256-6QkxQ1YlzQk0LljkRPyAeZPXMGagnWuG7cXthmrsAf0=";
    });
    poem = mkExtension "Poem" (fetchgit {
      url = "https://gerrit.wikimedia.org/r/mediawiki/extensions/Poem";
      rev = "1b19161825445ee41157ef651b6204817a64d7e2";
      hash = "sha256-9DLb9bQyjJp/2h5NX9uv+r3cnSamfsm9cYlOzWyJKdU=";
    });
    renameuser = mkExtension "Renameuser" (fetchgit {
      url = "https://gerrit.wikimedia.org/r/mediawiki/extensions/Renameuser";
      rev = "51fe3333a644f5d1a4138bea8104a7ba4862ec84";
      hash = "sha256-7Q1tn5v3O4adm5HJ4Z9DdodQbaIl/vnkSuccXUTM/zM=";
    });
    spamBlacklist = mkExtension "SpamBlacklist" (fetchgit {
      url = "https://gerrit.wikimedia.org/r/mediawiki/extensions/SpamBlacklist";
      rev = "75c722ad8276a36c7e4aaac8be67be311c9881bd";
      hash = "sha256-T9ZmR1EcWWBDQBcUW22hQKtR6i45D4lu30LF4DrVIEQ=";
    });
    syntaxHighlight = mkExtension "SyntaxHighlight_GeSHi" (fetchgit {
      url = "https://gerrit.wikimedia.org/r/mediawiki/extensions/SyntaxHighlight_GeSHi";
      rev = "c63aeb35737d30026dbdc3fa4a5a346d8c875c6e";
      hash = "sha256-tdY4OlCDxh3pdM747bdJ0VmEPYDx9XdIZjjuY4RAneA=";
    });
    wikiEditor = mkExtension "WikiEditor" (fetchgit {
      url = "https://gerrit.wikimedia.org/r/mediawiki/extensions/WikiEditor";
      rev = "abc1c63629f9f7802a627e0aa3262c3ac334f525";
      hash = "sha256-m9egVEKxv2vZnGt8ZubAvnf2ozYS0jCTgmxg9buzvW0=";
    });
  };
  skin = {
    vector = mkSkin "Vector" (fetchgit {
      url = "https://gerrit.wikimedia.org/r/mediawiki/skins/Vector";
      rev = "1e084256a129ca0e57a356c263808f98f3fdf3a4";
      hash = "sha256-GoXjStxT4OVkX2rA8BqHroS5ZxNLVgqaav75H4g2yog=";
    });
  };
in
php.buildComposerProject (finalAttrs: {
  pname = "puyonexus-wiki";
  version = "1.35.14";

  src = fetchgit {
    url = "https://gerrit.wikimedia.org/r/mediawiki/core.git";
    rev = "refs/tags/1.35.14";
    hash = "sha256-Nm878516MeetsOnkHgx+KOkfjMVzxExmdAH2q90SMaU=";
    fetchSubmodules = false;
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

  vendorHash = "sha256-PkPJvy+880y39VRYMZkXlt9vhANWSTp2BBiBsQfqt6E=";
  composerLock = ./composer.lock;

  composerRepository = php.mkComposerRepository {
    inherit (finalAttrs)
      pname
      src
      patchPhase
      composerLock
      vendorHash
      version
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
    ext.confirmEdit
    ext.gadgets
    ext.imageMap
    ext.inputBox
    ext.math
    ext.moderation
    ext.msUpload
    ext.nuke
    ext.parserFunctions
    ext.poem
    ext.renameuser
    ext.spamBlacklist
    ext.syntaxHighlight
    ext.wikiEditor
  ];

  skins = [
    skin.vector
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

      require_once('/etc/puyonexus/wiki/LocalSettings.php');

      # Extensions
      ${loadExts}

      # Skins
      ${loadSkins}
    '';
})
