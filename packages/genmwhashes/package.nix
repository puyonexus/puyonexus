{ writeShellApplication, nix-prefetch-git, jq }:

writeShellApplication {
  name = "genmwhashes";
  text = builtins.readFile ./genmwhashes.sh;
  runtimeInputs = [ nix-prefetch-git jq ];
}