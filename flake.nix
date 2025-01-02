{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    {
      self,
      nixpkgs,
      nixos-generators,
      sops-nix,
      deploy-rs,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      inputsOverlay = (final: prev: { inherit inputs; });
      localOverlay = import ./packages/overlay.nix;
      rev = self.shortRev or self.dirtyShortRev;
      overlays = [
        inputsOverlay
        localOverlay
      ];
      pkgs = import nixpkgs { inherit system overlays; };
      configMatrix = {
        machine = [ "ojama" ];
        environment = [
          "local"
          "staging"
          "production"
        ];
        modifier = [
          null
          "upgrade"
          "maintenancePlanned"
          "maintenanceUnplanned"
        ];
      };
      machineEnvironmentModules = machine: environment: [
        (./modules/environment + "/${environment}")
        (./modules/machine + "/${machine}")
        sops-nix.nixosModules.sops
        { nixpkgs.overlays = pkgs.lib.mkBefore overlays; }
        (
          { lib, ... }:
          {
            options = {
              puyonexus.rev = lib.mkOption { type = lib.types.nullOr lib.types.str; };
            };
            config = {
              puyonexus.rev = rev;
            };
          }
        )
      ];
    in
    {
      apps."${system}" = {
        deployHostKeys = {
          type = "app";
          program = toString (
            pkgs.writers.writeBash "deploy-host-keys" ''
              set -e
              if [ "$#" != "3" ] || [ "$1" == "--help" ]; then
                echo "Usage: $0 <environment> <machine> <target>"
                exit 1
              fi
              environment=$1
              machine=$2
              target=$3
              sshopts="-o StrictHostKeychecking=no -o UserKnownHostsFile=/dev/null"

              sendHostKey() {
                local environment=$1
                local machine=$2
                local target=$3
                local key=$4
                local perm=$5

                "${pkgs.sops}/bin/sops" exec-file "./secrets/$environment.yaml" \
                  "\"${pkgs.yq}/bin/yq\" -r \".$machine.\\\"$key\\\"\" {}" | \
                  sed -z '$ s/\n$//' | \
                  ssh $sshopts "root@$target" \
                  "install -m $perm /dev/stdin /etc/ssh/$key"
              }

              for key in ssh_host_{ed25519,rsa}_key; do
                sendHostKey $environment $machine $target $key 600
                sendHostKey $environment $machine $target ''${key}.pub 644
              done
              ssh $sshopts "root@$target" "systemctl restart sshd.service"
            ''
          );
        };

        default = {
          type = "app";
          program = toString (
            pkgs.writers.writeBash "run-local-vm" ''
              set -e
              echo "Running local VM. This may take a minute."
              echo "Once the VM is running, the following services should be available:"
              echo "- Puyo Nexus: http://puyonexus.localhost:8080"
              echo "- Grafana: http://grafana.puyonexus.localhost:8080"
              echo "- Mailpit: http://mailpit.puyonexus.localhost:8080"
              echo "Login with SSH: ssh -p 2222 root@puyonexus.localhost"
              echo "Hit Ctrl+C to shut down."
              echo "If your VM is corrupted, delete ojama.qcow2 to reset it."
              "${self.nixosConfigurations."vm-ojama-local".config.system.build.vm}/bin/run-ojama-vm" \
                -virtfs local,path=$PWD/data,security_model=none,mount_tag=puyonexus-data \
                -display none
            ''
          );
        };

        backup = {
          type = "app";
          program = toString (
            pkgs.writers.writeBash "backup-puyonexus" ''
              set -e

              if [ "$#" != "1" ] || [ "$1" == "--help" ]; then
                echo "Usage: $0 <host>"
                exit 1
              fi

              host="$1"

              BACKUP_NAME="$(date +"%Y%m%dT%H%M%S")"
              BACKUP_DIR="''${PWD}/backup/''${host}/''${BACKUP_NAME}"
              mkdir -p "''${BACKUP_DIR}"
              echo "''${BACKUP_DIR}"

              # Backup database.
              ssh "root@''${host}" \
                sh -c \${"''"}mysqldump --opt --single-transaction --max-allowed-packet=512M --compress puyonexus | zstd'\' \
                  > "''${BACKUP_DIR}/puyonexus.sql.zstd"

              # Backup data directory afterwards.
              # That way, the data folder is always up-to-date with the DB.
              # (Files *could* get deleted in-between, but files are rarely deleted.)
              rsync -rav "root@''${host}:/data" "''${BACKUP_DIR}"
            ''
          );
        };

        restore = {
          type = "app";
          program = toString (
            pkgs.writers.writeBash "restore-puyonexus" ''
              set -e

              if [ "$#" != "2" ] || [ "$1" == "--help" ]; then
                echo "Usage: $0 <host> <backup>"
              fi

              host="$1"
              backup="$(readlink -f "$2")"

              if [ ! -f "''${backup}/puyonexus.sql.zstd" ]; then
                echo "Database backup missing"
                exit 1
              fi

              if [ ! -d "''${backup}/data" ]; then
                echo "Storage backup missing"
                exit 1
              fi

              # Confirmation prompt
              echo "Will attempt to restore backup ''${backup} to host ''${host}."
              read -p "Is this OK? (y/N): " -n 1 -r
              echo
              if [[ ! $REPLY =~ ^[Yy]$ ]]
              then
                echo "Aborting."
                exit 1
              fi

              # Restore data directory.
              set -x
              rsync -rav \
                --update \
                --chown=puyonexus:users \
                --chmod=Du=rwx,Dg=rx,Do=rx,Fu=rw,Fg=r,Fo=r \
                "''${backup}/data" "root@''${host}:/"

              # Restore database.
              ${pkgs.lib.getExe pkgs.pv} "''${backup}/puyonexus.sql.zstd" | \
                ssh "root@''${host}" \
                  sh -c \${"''"}zstd -d | mysql --database puyonexus --compress'\'
            ''
          );
        };
      };

      nixosConfigurations =
        let
          inherit (nixpkgs.lib)
            mapCartesianProduct
            nameValuePair
            nixosSystem
            optionals
            singleton
            ;
          mkSystems =
            platform: systemModules:
            builtins.listToAttrs (
              mapCartesianProduct (
                {
                  machine,
                  environment,
                  modifier,
                }:
                let
                  name = "${platform}-${machine}-${environment}${
                    pkgs.lib.optionalString (modifier != null) "-${modifier}"
                  }";
                  modifierModules = optionals (modifier != null) (
                    singleton (./modules/modifiers + "/${modifier}.nix")
                  );
                  modules = (machineEnvironmentModules machine environment) ++ modifierModules ++ systemModules;
                in
                nameValuePair name (nixosSystem {
                  system = "x86_64-linux";
                  inherit modules;
                })
              ) configMatrix
            );
          vm = mkSystems "vm" [ ./modules/qemu-vm.nix ];
          do = mkSystems "do" [ (nixpkgs + "/nixos/modules/virtualisation/digital-ocean-config.nix") ];
        in
        vm
        // do
        // {
          base = nixosSystem {
            system = "x86_64-linux";
            modules = [
              ./modules/machine/base
              (nixpkgs + "/nixos/modules/virtualisation/digital-ocean-config.nix")
            ];
          };
        };

      packages."${system}" = {
        digitalOceanImage = nixos-generators.nixosGenerate {
          pkgs = nixpkgs.legacyPackages."${system}";
          modules = [ ./modules/machine/base ];
          format = "do";
        };
        nixfmt = pkgs.nixfmt-rfc-style;
        genhostkeys = pkgs.genhostkeys;

        chainsim = pkgs.puyonexusPackages.chainsim;
        forum = pkgs.puyonexusPackages.forum;
        home = pkgs.puyonexusPackages.home;
        wiki = pkgs.puyonexusPackages.wiki;
      };

      deploy =
        let
          inherit (nixpkgs.lib)
            nameValuePair
            ;
          mkMachineNodes =
            {
              platform,
              machine,
              environment,
              hostname,
              extraArgs ? { },
            }:
            builtins.listToAttrs (
              map (
                modifier:
                let
                  name = "${platform}-${machine}-${environment}${
                    pkgs.lib.optionalString (modifier != null) "-${modifier}"
                  }";
                in
                nameValuePair name (
                  extraArgs
                  // {
                    inherit hostname;
                    profiles.system = {
                      path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations."${name}";
                    };
                  }
                )
              ) configMatrix.modifier
            );
        in
        {
          user = "root";
          sshUser = "root";
          nodes =
            mkMachineNodes {
              platform = "vm";
              machine = "ojama";
              environment = "local";
              hostname = "puyonexus.localhost";
              extraArgs = {
                sshOpts = [
                  "-p"
                  "2222"
                ];
              };
            }
            // mkMachineNodes {
              platform = "do";
              machine = "ojama";
              environment = "staging";
              hostname = "ojama.puyonexus-staging.com";
            }
            // mkMachineNodes {
              platform = "do";
              machine = "ojama";
              environment = "production";
              hostname = "ojama.puyonexus.com";
            };
        };

      checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
    };
}
