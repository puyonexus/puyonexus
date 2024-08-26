{ lib, ... }:
{
  options = {
    puyonexus.environment = {
      name = lib.mkOption { type = lib.types.str; };
    };
  };
}
