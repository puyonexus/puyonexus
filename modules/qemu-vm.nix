{
  config,
  pkgs,
  lib,
  modulesPath,
  ...
}:
{
  imports = [ (modulesPath + "/virtualisation/qemu-vm.nix") ];

  config = {
    boot.loader.grub.forceInstall = true;

    virtualisation.diskSize = 10240;
    virtualisation.forwardPorts =
      let
        sshPort = config.puyonexus.ssh.port;
        httpPort = config.puyonexus.nginx.httpPort;
        httpsPort = config.puyonexus.nginx.httpsPort;
      in
      [
        # SSH
        {
          from = "host";
          host.port = sshPort;
          guest.port = sshPort;
        }
        # HTTP
        {
          from = "host";
          host.port = httpPort;
          guest.port = httpPort;
        }
      ]
      ++ lib.optionals config.puyonexus.nginx.useHttps [
        # HTTPS
        {
          from = "host";
          host.port = httpsPort;
          guest.port = httpsPort;
        }
      ];
    virtualisation.qemu.options =
      let
        sopsBin = "${pkgs.sops.out}/bin/sops";
        yqBin = "${pkgs.yq.out}/bin/yq";
        copyHostKeys = pkgs.writeShellScript "copy-host-keys" ''
          set -e
          TMPDIR=$1
          mkdir --mode=700 -p "$TMPDIR/hostkeys"
          decodeHostKey() {
            local name=$1
            local host="${config.system.name}"
            install -m 600 \
              <("${sopsBin}" exec-file "${config.sops.defaultSopsFile}" \
              "\"${yqBin}\" -r \".$host.\\\"$name\\\"\" {}" | sed -z '$ s/\n$//') \
              "$TMPDIR/hostkeys/$name"
          }
          for key in ssh_host_{ed25519,rsa}_key{,.pub}; do
            decodeHostKey $key
          done
          echo "$TMPDIR/hostkeys"
        '';
      in
      [ "-virtfs local,path=$(${copyHostKeys} $TMPDIR),security_model=none,mount_tag=host-keys" ];
    virtualisation.msize = 524288;
    virtualisation.fileSystems = {
      "/etc/hostkeys" = {
        device = "host-keys";
        fsType = "9p";
        neededForBoot = true;
        options = [
          "trans=virtio"
          "version=9p2000.L"
          "msize=${toString config.virtualisation.msize}"
        ];
      };
      "/hostdata" = {
        device = "puyonexus-data";
        fsType = "9p";
        neededForBoot = true;
        options = [
          "trans=virtio"
          "version=9p2000.L"
          "msize=${toString config.virtualisation.msize}"
        ];
      };
    };
    boot.initrd.kernelModules = [ "fuse" ];
    system.activationScripts = {
      hostkeys.text = ''
        cp /etc/hostkeys/ssh_host_* /etc/ssh
        chmod 600 /etc/ssh/ssh_host_*
        chmod 644 /etc/ssh/ssh_host_*.pub
      '';
      datamode.text = ''
        mkdir -p /data
        ${pkgs.bindfs}/bin/bindfs -u puyonexus -g users /hostdata /data
      '';
    };
  };
}
