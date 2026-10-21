final: prev:
let
  inherit (final) callPackage;
in
{
  # Emergency fix for CVE-2026-109618 and CVE-2026-109619.
  php83 = prev.php83.buildEnv {
    version = "8.3.36";
    hash = "sha256-RvS0XjaI7SsYGQFae1MsFbUcwFW907E/0A3f7r7tzV8=";
    extensions =
      { enabled, ... }:
      map (
        extension:
        if extension.extensionName != "filter" then
          extension
        else
          extension.overrideAttrs (old: {
            # Workaround for test failures caused by Nix packaging issues
            preCheck = (old.preCheck or "") + ''
              substituteInPlace \
                tests/oom_filter_default_encoded.phpt \
                tests/oom_filter_input.phpt \
                tests/oom_filter_input_array.phpt \
                --replace-fail "'-n'," "'-n', '-d', 'extension=' . __DIR__ . '/../modules/filter.so',"
            '';
          })
      ) enabled;
  };

  genhostkeys = callPackage ./genhostkeys/package.nix { };

  genmwhashes = callPackage ./genmwhashes/package.nix { };

  puyonexusPackages = callPackage ./puyonexus { };
}
