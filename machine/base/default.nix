{
  imports = [
    ../../puyonexus/openssh.nix
    ../../puyonexus/users.nix
  ];

  config = {
    system.stateVersion = "24.05";
    networking.hostName = "base";

    puyonexus.ssh.enable = true;
  };
}
