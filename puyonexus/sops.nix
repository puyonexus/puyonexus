{ config, ... }: {
  config = {
    sops = {
      age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
      defaultSopsFile = ../secrets + "/${config.puyonexus.environment.name}.yaml";
    };
  };
}
