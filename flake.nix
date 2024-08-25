{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
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
        (final: prev: {
          # Workaround for an obscure issue in build-vm with nixos-24.05.
          pipewire = prev.pipewire.overrideAttrs (prevAttrs: {
            version = "1.2.1";
            mesonFlags = prevAttrs.mesonFlags ++ [ (final.lib.mesonEnable "snap" false) ];
            src = final.fetchFromGitLab {
              domain = "gitlab.freedesktop.org";
              owner = "pipewire";
              repo = "pipewire";
              rev = "1.2.1";
              sha256 = "sha256-CkxsVD813LbWpuZhJkNLJnqjLF6jmEn+CajXb2XTCsY=";
            };
          });
        })
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
      };
      machineEnvironmentModules = machine: environment: [
        (./environment + "/${environment}")
        (./machine + "/${machine}")
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
      apps."${system}" = rec {
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
              echo "- Mailpit: http://puyonexus.localhost:8025"
              echo "Login with SSH: ssh -p 2222 root@puyonexus.localhost"
              echo "Hit Ctrl+C to shut down."
              echo "If your VM is corrupted, delete ojama.qcow2 to reset it."
              "${self.nixosConfigurations."vm.ojama.local".config.system.build.vm}/bin/run-ojama-vm" \
                -virtfs local,path=$PWD/data,security_model=none,mount_tag=puyonexus-data \
                -display none
            ''
          );
        };
      };

      nixosConfigurations =
        let
          inherit (nixpkgs.lib) mapCartesianProduct nameValuePair nixosSystem;
          mkSystems =
            key: modules:
            builtins.listToAttrs (
              mapCartesianProduct (
                { machine, environment }:
                nameValuePair "${key}.${machine}.${environment}" (nixosSystem {
                  system = "x86_64-linux";
                  modules = (machineEnvironmentModules machine environment) ++ modules;
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
              ./machine/base
              (nixpkgs + "/nixos/modules/virtualisation/digital-ocean-config.nix")
            ];
          };
        };

      packages."${system}" = {
        digitalOceanImage = nixos-generators.nixosGenerate {
          pkgs = nixpkgs.legacyPackages."${system}";
          modules = [ ./machine/base ];
          format = "do";
        };
        nixfmt = pkgs.nixfmt-rfc-style;
        genhostkeys = pkgs.genhostkeys;

        chainsim = pkgs.puyonexusPackages.chainsim;
        forum = pkgs.puyonexusPackages.forum;
        home = pkgs.puyonexusPackages.home;
        wiki = pkgs.puyonexusPackages.wiki;
        wiki1_35 = pkgs.puyonexusPackages.wiki1_35;
      };

      deploy = {
        user = "root";
        sshUser = "root";
        nodes = {
          ojamaLocal = {
            sshOpts = [
              "-p"
              "2222"
            ];
            hostname = "puyonexus.localhost";
            profiles.system = {
              path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations."vm.ojama.local";
            };
          };
          ojamaStaging = {
            hostname = "ojama.puyonexus-staging.com";
            profiles.system = {
              path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations."do.ojama.staging";
            };
          };
          ojamaProduction = {
            hostname = "ojama.puyonexus.com";
            profiles.system = {
              path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations."do.ojama.production";
            };
          };
        };
      };

      checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
    };
}
