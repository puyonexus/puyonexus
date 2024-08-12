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

        Temporary: you will need to run the multi-stage migration for current Puyo Nexus production backups.

        ```console
        $ ssh -tp 2222 root@puyonexus.localhost multi-update-wiki
        ```

        The multi-stage migration is very slow.

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
