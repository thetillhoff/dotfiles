# First deploy of an env

Do each phase once per env, `dev` first. Each phase has a check. Do not go on before the check passes.

## 1. Credentials

```sh
source assume <project>-<env>/AdministratorAccess
aws sts get-caller-identity
```

**Check:** `Account` is the account of the env (README, "Deploy").

## 2. Bootstrap

```sh
task bootstrap:<env>
```

**Check:** the bucket `<project>-pulumi-state-<account>` and the alias `alias/<project>-pulumi-secrets` exist. Wait until the Lambda quota shows 1000: `aws lambda get-account-settings`.

## 3. Shared stack

Only before the first env of the project, with the credentials of prd:

```sh
task deploy:shared
```

**Check:** the zone is active at Cloudflare. Set the name servers at the registrar if the zone is new.

## 4. Stack and secrets

```sh
task stack:<env>
cd infra
export PULUMI_BACKEND_URL='s3://<project>-pulumi-state-<account>?region=eu-central-1'
pulumi config set --stack <env> --secret cloudflare:apiToken <token>
```

**Check:** `Pulumi.<env>.yaml` has `secretsprovider: awskms://alias/...`. Commit the file.

<!-- product secrets: put each in an SSM SecureString by hand, never in Pulumi state -->

## 5. Deploy

```sh
task deploy:<env>
```

**Check:** the product checks of the README. Open each verification mail (alarm subscription, mail sandbox).

## When it fails

- **Concurrency error on a Lambda** ("below its minimum value of [10]"): the quota is not raised yet. Wait, then deploy again.
- **Budget cannot be created**: enable Cost Explorer once in the Billing console, then deploy again. Do not delete the budget.
- **Half-created resource**: run `pulumi refresh --stack <env>` with `PULUMI_BACKEND_URL` set, then preview again.
- **Teardown**: `pulumi destroy --stack <env>`, then `pulumi stack rm --preserve-config <env>`. Destroy `infra/bootstrap` last.
