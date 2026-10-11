# infra

The Pulumi program (TypeScript) of `<project>`. One stack per env (`dev`, `prd`), state in S3, secrets in KMS. The other two projects are `infra/bootstrap` (account baseline) and `infra/shared` (what dev and prd share).

## Layout

- `index.ts` - stack composition and outputs
- `config.ts` - reads the stack config. Every difference between dev and prd is a field here.
- `records.ts` - the Cloudflare records of `domainName`
- `budget.ts` - the monthly cost budget
- `lambda.ts` - helper for a Lambda with role, log group and reserved concurrency
- `test/` - the program against Pulumi mocks, with the real `Pulumi.<env>.yaml`

<!-- one line per file of the product -->

## Stack config

Set per stack in `Pulumi.<env>.yaml`. Never branch on the stack name in code.

| Key | Meaning |
| --- | --- |
| `aws:allowedAccountIds` | The one account of the env. A wrong account fails before a change. |
| `budgetNotificationEmail` | Gets the budget mails. No default. |
| `monthlyBudgetUsd` | Optional, default 20. |

<!-- product keys -->

## Cost controls

| Control | Where | Effect |
| --- | --- | --- |
| Reserved concurrency of each Lambda | `lambda.ts` | Stops a runaway. Excess calls get throttled. |
| Throttle of the API stage | `index.ts` | Stops a request flood. |
| AWS Budgets, mail at 80 % and 100 % | `budget.ts` | Reports slow drift. Its data lags up to 24 hours, so it never replaces the two caps. |

The account quota for Lambda concurrency starts at 10. `task bootstrap` requests 1000. Wait until `aws lambda get-account-settings` shows it, then deploy.

## DNS

| Project | Owns |
| --- | --- |
| `infra/shared` (stack `shared`) | The Cloudflare zone and the records that every env shares |
| `infra` (stacks `dev`, `prd`) | Only the records under its own `domainName` |

prd uses the apex. Every other env adds an `<env>.` prefix. Two stacks never write one record. Each stack has its own Cloudflare token as a stack secret:

```sh
pulumi config set --stack <env> --secret cloudflare:apiToken <token>
```

Run it in the stack directory with `PULUMI_BACKEND_URL` set as `task deploy` sets it. `infra/shared` keeps its state in the bucket and the KMS key of prd.

## Commands

```sh
task preview ENV=dev
task deploy ENV=dev      # ENV=shared first for a new env
```

The first deploy of an env: `docs/runbooks/first-deploy.md`.
