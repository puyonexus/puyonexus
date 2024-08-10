# Puyo Nexus
This repository contains the source code for Puyo Nexus.

## Running locally
You must have Nix installed with `nix-command` and `flakes` experiments enabled.

Run `nix run` to run the local VM.

SSH will be available on port 2222. You can log in using `ssh -p 2222 root@puyonexus.localhost`. The default root password on localhost is `root`.

### Wiki Setup
To initialize the wiki, log via SSH and run `init-wiki`.

### Secrets
For local development, you can use the provided local age key to decrypt secrets.

```console
SOPS_AGE_KEY_FILE=$PWD/localkey.txt sops ./secrets/local.yaml
```

The local key can not be used to decrypt production or staging secrets.
