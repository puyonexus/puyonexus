{
  stdenvNoCC,
  writeText,
  fetchurl,
  fetchFromGitHub,
  unzip,
}:
let
  config = writeText "config.php" "<?php return require_once(getenv('PUYONEXUS_FORUM_CONFIG_PATH')); ?>";
  mediaembed = fetchurl {
    url = "https://www.phpbb.com/customise/db/download/205090";
    hash = "sha256-SrcZWUqk0H92ONx+TMM4Hcr0tOdMM2f5pTUFLF/oVCg=";
  };
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "puyonexus-forum";
  version = "unstable";

  src = fetchurl {
    url = "https://download.phpbb.com/pub/release/3.3/3.3.12/phpBB-3.3.12.tar.bz2";
    hash = "sha256-F4KOlhQGKRRQh4qlm8uwTWQucRzAAovoMb23yAOxOzs=";
  };

  postPatch = ''
    cp ${config} config.php
  '';

  installPhase = ''
    DESTDIR="$out"/share/php/"${finalAttrs.pname}"/
    mkdir -p "$out"/share/php/
    cp -r . "$DESTDIR"
    rm -fr "$DESTDIR"/install
    cp -r ${./styles/pronexus} "$DESTDIR"/styles/pronexus
    mkdir -p "$DESTDIR"/ext/puyonexus
    cp -r ${./ext/puyonexus/additions} "$DESTDIR"/ext/puyonexus/additions
    ${unzip}/bin/unzip ${mediaembed} -d "$DESTDIR"/ext

    # phpBB does not have a proper way to override all of the directories.
    # We will use out-of-store symlinks as a workaround...
    rm -fr "$DESTDIR"/cache
    rm -fr "$DESTDIR"/files
    rm -fr "$DESTDIR"/store
    rm -fr "$DESTDIR"/images/avatars/upload
    rm -fr "$DESTDIR"/images/ranks
    ln -s /data/forum-cache "$DESTDIR"/cache
    ln -s /data/forum-files "$DESTDIR"/files
    ln -s /data/forum-store "$DESTDIR"/store
    ln -s /data/forum-avatars "$DESTDIR"/images/avatars/upload
    ln -s /data/forum-ranks "$DESTDIR"/images/ranks
  '';
})
