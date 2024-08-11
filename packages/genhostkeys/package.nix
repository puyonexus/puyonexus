{ lib, buildGoModule }:
buildGoModule {
  pname = "genhostkeys";
  version = "unstable";
  src = ./.;
  vendorHash = "sha256-1xaSlEhTEVBBd8u92rSk+0eOm9EY3zWrdrxu4G5uj9A=";
}
