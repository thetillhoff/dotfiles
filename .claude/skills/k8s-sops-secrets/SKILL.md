---
name: k8s-sops-secrets
description: Use when a change needs a new Kubernetes Secret with a value that only the user has (token, password, webhook URL) in a SOPS-encrypted repo. Covers how to hand the file over so the user only fills in the value.
---

# Secret that the user must fill in

The user must not build the file from scratch. Prepare it fully, then give one command.

- Write the complete `Secret` manifest (`name`, `namespace`, `stringData` key) with a placeholder value, then run `sops encrypt -i <file>` and commit it. Never commit a plaintext placeholder.
- Give exactly one command with the real path, for the user to run with `!`: `sops edit <file>`. Add nothing else. The user then commits and merges.
- Before you hand it over, check that the `.sops.yaml` `path_regex` matches the file, and that the `Kustomization` that applies it has `decryption` set.
- Never run `sops decrypt` or read a secret value yourself. The classifier blocks it, and you do not need it.
