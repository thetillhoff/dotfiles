# infra/bootstrap

The account baseline that `infra/` and `infra/shared` need before their first run: the S3 bucket for the Pulumi state, the KMS key for the Pulumi secrets, and the Lambda concurrency quota.

## Why it is a separate project

Pulumi cannot create the bucket that holds its own state. This project is the one project on the local backend (`file://~`, pinned in `Pulumi.yaml`). Its state holds no secrets, so the empty passphrase protects nothing. If the state file is lost, the bucket and the key still exist and can be imported again.

## One stack per AWS account

| Stack | Creates | Console colour |
| --- | --- | --- |
| `dev` | state bucket, KMS key with alias, Lambda quota request | none |
| `prd` | state bucket, KMS key with alias, Lambda quota request | red |

- The account IDs are in `Pulumi.<stack>.yaml` (`aws:allowedAccountIds`). A run with credentials of another account fails before it changes anything.
- The state bucket is `<project>-pulumi-state-<account>`. It is versioned, private and encrypted. Old versions expire after 90 days.
- The KMS key has the alias `alias/<project>-pulumi-secrets` and a 30-day deletion window.
- The default region of the console is a per-user setting with no API. Set it once by hand to `eu-central-1`.

## Commands

Get credentials first (`source assume <profile>`, unpiped). Then run from the repo root:

```sh
task bootstrap ENV=dev
```

`task stack ENV=<env>` then creates the stack of `infra/` on the new backend, with the alias as secrets provider.

## Cost

The KMS key costs about $1 per month per account. S3 costs pennies. A Pulumi passphrase in SSM is free but is one long-lived secret that decrypts every stack. KMS has no shared secret, IAM controls access, CloudTrail logs each decrypt, and the key rotates itself.
