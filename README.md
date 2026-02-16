# Puyo Nexus
This repository contains the source code for Puyo Nexus.

## Running locally
You must have Nix installed with `nix-command` and `flakes` experiments enabled. The default flake app will start a headless VM using Qemu.

SSH will be available on port 2222. You can log in using `ssh -p 2222 root@puyonexus.localhost`. The default root password on localhost is `root`.

### Step-by-step

1. Install Nix. I recommend [Determinate Nix Installer](https://github.com/DeterminateSystems/nix-installer?tab=readme-ov-file#usage).

    ```console
    $ curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
    ```

1. **Optional:** You may get slightly improved build times by enabling the Puyo Nexus Nix cache. (Most binaries will be provided from cache by NixOS Hydra either way.)

    ```console
    $ nix-env -iA cachix -f https://cachix.org/api/v1/install
    $ cachix use puyonexus
    ```

1. Run the development server. After the build completes, it will still take a few seconds for the server to become ready, so be patient. You can try loading <http://puyonexus.localhost:8080> in a browser to see if it's working yet.

    ```console
    $ SOPS_AGE_KEY_FILE=$PWD/localkey.txt nix run
    ```

1. On another terminal, initialize the Wiki.

      - From scratch: `ssh -tp 2222 root@puyonexus.localhost init-wiki`

      - From a backup: `<puyonexus.sql.zstd ssh -p 2222 root@puyonexus.localhost -- sh -c "unzstd -c | mysql"`

        (Restoring from backup may fail if you already initialized from scratch.)

1. Puyo Nexus should be running locally. Try browsing to it via <http://puyonexus.localhost:8080>.

> [!IMPORTANT]
> If you are running this under a virtual machine setup like WSL2, you may have trouble accessing services from the host machine.

### Wiki Setup
To initialize the wiki, log via SSH and run `init-wiki`.

### Secrets
For local development, you can use the provided local age key to decrypt secrets.

```console
SOPS_AGE_KEY_FILE=$PWD/localkey.txt sops ./secrets/local.yaml
```

The local key can not be used to decrypt production or staging secrets.

## Deploying to a Server

There are many ways to install Puyo Nexus to a server. Here is the current setup we are using:

1. Boot from the standard NixOS installation media. A minimal ISO works.

1. Install the base configuration: `curl -fsSL https://raw.githubusercontent.com/puyonexus/puyonexus/refs/heads/master/install-here.sh | sudo bash -s`

1. Reboot into the base install.

1. Deploy host keys: `nix run .#deployHostKeys [configuration] [hostname] [server IP]` - for example, to deploy staging ojama to 1.2.3.4, the command would be `nix run .#deployHostKeys staging ojama 1.2.3.4`.

   Host keys are typically used also as keys for sops-nix. Beware that you shouldn't use the same SSH host key on a different machine, so for each machine you should have a unique hostname and host key pair stored in sops, and each host key should also be a recipient in sops as well so it can unlock the secrets.

1. Restore the database and files from a backup: `nix run .#restore [hostname] [backup folder]`. The backup folder should have a `puyonexus.sql.zstd` database file, and a `data` folder with the file storage.

1. Finally, deploy the actual full configuration. The available configurations are defined in `flake.nix` under the `deploy` output key. `nix run github:serokell/deploy-rs -- .#ojamaStaging`

## Maintenance Page
There is a static site in `maintenance` that contains a basic maintenance page. Right now, it is set up for use with Cloudflare Pages.

To turn it on, go to the Cloudflare Pages app for it and add puyonexus.com as a custom domain. Don't forget to customize the text and deploy it first.
