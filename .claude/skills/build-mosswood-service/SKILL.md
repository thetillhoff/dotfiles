---
name: build-mosswood-service
description: Use when you start a new service in the mosswood family (a sibling of mosswood-app and sendpdf), or when you align an existing one. Holds the shared repo layout, branches, AWS and Pulumi structure, Taskfile, docs and CLAUDE.md conventions. Also use to check that a sibling repo still follows them.
---

# Build a mosswood service

A mosswood service is one repo, one product, on AWS with Pulumi.
`mosswood-app` (Go) and `sendpdf` (Node) are the reference repos.
Copy the shape from them. The language and the product can differ. The rest must not.

## Repo layout

```text
AGENTS.md                rules for agents (see "Agent files")
CLAUDE.md                `# Claude`, a blank line, `@AGENTS.md`
README.md                environments table, dev commands, deploy, layout
package.json             tooling only when the service is not Node: markdownlint-cli as exact devDependency
TODO.md                  open work only
KNOWN-ISSUES.md          accepted gaps
Taskfile.yml             the one entry point for test, deploy, bootstrap
.markdownlint.json       MD013 off, MD010 code_blocks off
.markdownlintignore      node_modules/, dist/, generated or scratch markdown
.gitignore               templates/gitignore, plus build output. No `.env` patterns: a service has no `.env` file.
renovate.json            dependency updates, templates/renovate.json
infra/                   Pulumi project, one stack per env
infra/bootstrap/         Pulumi project, one stack per AWS account
infra/shared/            Pulumi project, stack `shared`
docs/superpowers/        plans and specs
.claude/skills/          repo skills, only when a rule needs a procedure
```

- Copy `templates/` and replace `<project>`, `<dev-account>`, `<prd-account>`. A template is a start. The repo may need more, never less of what it names.
- Scaffold with `pulumi new aws-typescript --generate-only`, not by hand. See "Pulumi" for the CLI traps.
- `npx --no-install markdownlint-cli --ignore node_modules -- '**/*.md'` must exit 0 over the whole repo. Pin the tool as an exact `devDependency`: `verify` runs before a deploy, so an unpinned `npx` would run unreviewed code with prd credentials.
- A plan or spec holds the contract. The code and `TODO.md` are the live truth.

## Git

- Default branch: `dev`. It deploys to the dev env.
- `main` is the state that prd gets. Merge `dev` into `main` only for a prd release.
- Commit after each verified task. Push only when asked.
- `task deploy` is run by the operator on the local machine. CI never deploys.
- No CI and no GitHub Actions unless the user asks. Dependency updates: always Renovate (`renovate.json`), never Dependabot.

## Environments and secrets

Three layers. Every service has the same ones.

| Layer | Runs | Providers, auth, mail |
| --- | --- | --- |
| Local (`task dev`, `task test`) | On the machine, no AWS | Mocks or stubs: a `*.mock.js` twin (sendpdf) or DynamoDB Local with stubbed auth (mosswood-app). One switch, static requires. A server with stubbed auth binds `127.0.0.1`, never all interfaces: `task a11y` and `task dev` leave it running with a fixed login. |
| dev | Own AWS account | Real AWS. Fakes for every paid or irreversible provider, mail only to an allow list, search engines blocked. |
| prd | Own AWS account | Real. |

- A secret is never a `.env` file. There are two places:
  - Runtime secrets: SSM Parameter Store SecureString, never Secrets Manager. Pulumi seeds a placeholder with `ignoreChanges`, so the parameter and its IAM grant exist before the first run. The operator writes the real value by hand once. The value never enters code or Pulumi state.
  - IaC secrets (the Cloudflare token): Pulumi stack secrets, encrypted with the KMS key of the account.
- Give each real provider client a mock or fake twin with the same interface. Change both together.
- dev guards the whole site with HTTP basic auth: the optional stack secret `basicAuth` (`user:password`), unset on prd. It is the one runtime secret that is a Pulumi stack secret, not SSM: a dev-only shared gate password, and an SSM read would add a failure path to the gate. The value is `dev:` plus a static password that the operator picks, so it is easy to share on a device. It is a gate, not a protection: use a generated value for an internal portal or any page that holds real data. Set it with `task pulumi:dev -- config set --secret basicAuth` and type the value at the prompt. Static sites do it in the CloudFront viewer-request Function (sendpdf, `index.ts`); a Lambda-served console does it in the handler (mosswood-app, `internal/api/basicauth.go`). The provider webhook stays open. Strip a passed Basic header if the app reads `Authorization` itself.

## AWS

- One account per env: `dev`, `prd`. The management account is separate: no stack, task, enum or doc of a service names it.
- Credentials: `source assume <project>-<env>/AdministratorAccess`, unpiped. `pulumi:<env>` checks the account itself.
- Each stack config sets `aws:allowedAccountIds`. A wrong account fails before it changes anything.
- Region `eu-central-1`, set once in the `Pulumi.yaml` of the project (`aws:region: { value: ... }`). Only the registrar and CloudFront certificates use `us-east-1`.
- Secrets: SSM Parameter Store SecureString. Never in the Pulumi state, never through a template.
- dev runs the same program and code as prd. Every difference is stack config. Never branch on the stack name.
- Cost controls are required: reserved concurrency on every Lambda, a throttle on the API stage, and a monthly budget with mail at 80 % and 100 % (`templates/budget.ts`, `budgetNotificationEmail` in each stack config). See "Conditional aspects" for the Lambda quota.
- dev uses fakes for paid or irreversible providers. A fake records calls and can force failures. It never deduplicates or retries.

## Pulumi

Three projects, TypeScript, `typescript@5`:

| Project | Stacks | State | Holds |
| --- | --- | --- | --- |
| `infra/bootstrap` | one per account (`dev`, `prd`) | local (`file://~`), no secrets | state bucket `<project>-pulumi-state-<account>` (versioned, private, encrypted; old versions and `.pulumi/backups/` expire after 90 days), KMS key for secrets, console colour (prd red) |
| `infra/shared` | `shared` | S3 + KMS of prd, until a shared account exists | what dev and prd share: the Cloudflare zone, mail forwarding |
| `infra` | `dev`, `prd` | S3 + KMS of the env account | everything else |

- `Pulumi.yaml` of bootstrap pins `backend.url: file://~`. Its passphrase is empty.
- Order of the first runs: `task bootstrap:prd` first, because `infra/shared` (the DNS of every env) borrows the bucket and the KMS key of prd, so it needs prd credentials. Then `task deploy:shared`. `task bootstrap:dev` is needed before the first dev deploy. `task deploy:<env>` comes last.
- Bootstrap and the regular program are separate projects on purpose: Pulumi cannot create the bucket of its own state. Never fold bootstrap into `infra/`.
- `infra/shared` has no account of its own. It reuses the prd bucket and key until a person without prd access must change DNS.
- Create a stack with `--secrets-provider` always. A bare `stack init` on S3 falls back to a passphrase.
- Use the KMS alias (`awskms://alias/<project>-pulumi-secrets?region=eu-central-1`) as secrets provider, never the key ARN or ID. `task stack:<env>` does it.
- `pulumi stack rm` deletes `Pulumi.<stack>.yaml`. Pass `--preserve-config`.
- `pulumi import`: pass `--protect=false` when the project uses no protect flags.
- Scaffold on this host with `PULUMI_BACKEND_URL=file://~ pulumi new <template> --generate-only`.
- In `Pulumi.yaml`, write `aws:region: { value: ... }`. The CLI rejects `default:`.
- IaC is Pulumi or CDK only. Never CloudFormation directly, never `Cfn*` constructs.
- A test runs the program against Pulumi mocks with the real `Pulumi.<env>.yaml`.

## DNS

- Cloudflare, as code. `infra/shared` owns the zone and shared records.
- Env stacks look the zone up and own only the records under their own domain.
  prd uses the apex. Every other env adds a `<env>.` prefix. Two stacks never write one record.
- Records are DNS only (`proxied: false`).
- Each stack has its own Cloudflare token as a stack secret. Run `task deploy:shared` before the first env deploy.

## Taskfile

Start from `templates/Taskfile.yml`. Tasks: `verify`, `test`, `bootstrap:<env>`, `stack:<env>`, `preview:<env>`, `deploy:<env>`, `pulumi:<env>`, `reset-dev`. A product adds its own (`dev`, `build`).

- Prefer Taskfile over Makefile. Review an existing Makefile against this list and port it.
- Test a Taskfile change with `task <name> --dry`. A dry run still runs the preconditions, so put a stub `aws` that prints a fixed account on the `PATH`, and the real credentials are not needed. Then run the read-only tasks against dev.
- The env is the wildcard of the task name (`"pulumi:*"`, `task deploy:dev`), never an `ENV=` variable. `pulumi:<env>` is the one place that sets `PULUMI_BACKEND_URL` and appends `--stack`: `task pulumi:dev -- config get basicAuth`. `stack`, `preview`, `deploy` and `reset-dev` call it. A service with one env keeps plain task names and one `pulumi` task (mosswood-web).
- Put the project name and both account IDs once in the top `vars` (`PROJECT`, `DEV_ACCOUNT`, `PRD_ACCOUNT`). `PROJECT` names the owner of the state bucket and the KMS alias, so the bucket, the alias and the other names derive from it. `pulumi:<env>` and `bootstrap:<env>` compare `aws sts get-caller-identity` with the account of the env in a precondition and refuse another account.
- Set `PULUMI_BACKEND_URL` on the command (in `pulumi:*`), never in `env:`. A shell variable beats `env:` and sends a task to the wrong account.
- A `vars:` map rejects the YAML merge key. Put every variable in the anchored map.
- `task stack:<env>` creates a missing stack with the alias as secrets provider. `preview` and `deploy` run it. This replaces a manual `pulumi stack init`. `preview` always passes `--diff`.
- `deploy` refuses a branch that does not match the env. `shared` runs from any branch. `deploy` runs `verify` first.
- `reset-dev` empties every bucket and table of the dev stack, then runs `pulumi up --refresh` to re-seed `TableItem` rows. It uses `templates/reset-dev.sh` as `scripts/reset-dev.sh`. The script reads the ids from the stack state and refuses a non-dev account. It does not clean Cognito or SSM: add that per service.
- A product with a UI adds `a11y`: `frontend-verify` in Docker, one run for each language (`--locale`), signed in with the stub cookie when the pages need a login (`--storage-state`). Mount only `.a11y/` (script and site `:ro,z`), pin every npm package, and start the server on the host. `a11y` is not part of `verify`: it takes minutes.
- `default` lists the tasks. A destructive task uses `prompt:` and refuses the wrong account in its script. `install` runs `npm install` in every Node project.
- `verify` is the done gate. Include each check that fits the project: markdown lint, formatter, vet or lint, `tsc --noEmit` of every Pulumi project, the tests (twice), the deployable build. Skip a check that does not fit. Add a better one when the project has it. Never force a check that has no meaning there.

## Conditional aspects

Apply each aspect only when the service has the named resource.

- **Lambda (any function):**
  - A new account has a concurrency quota of 10, and Lambda keeps 10 unreserved. Every reserved concurrency then fails with "below its minimum value of [10]".
  - `infra/bootstrap` requests 1000 (`ServiceQuota`, `L-B99A9384`, `templates/bootstrap-index.ts`). Run `task bootstrap:<env>` before the first deploy of the env. AWS can take time to grant it.
  - Check with `aws lambda get-account-settings --region eu-central-1`.
  - Give the function code as a file: `FileAsset` (Go binary) or `FileArchive` (bundle written to `infra/.build/<name>/`, in `.gitignore`). Never a `StringAsset`: the state stores its text twice, and a state above 5 MB makes the AWS SDK warn about multipart checksums on every read.
- **Log groups (Lambda, CloudFront, any other):**
  - Set `retentionInDays` on each log group. The default is never expire.
  - Use one number for all of them. Put it in the stack config or one constant.
  - The privacy notice states it when the service has one. The notice, the log groups and the CloudFront log rule change together. A test asserts the number.
- **S3 buckets:**
  - Give each bucket a lifecycle rule, or write down why it has none (invoices: statutory retention, so no expiry).
  - A bucket of user uploads expires its objects. The rule is the backstop: the code deletes the object earlier. Keep the days in line with the privacy notice.
  - A versioned bucket also expires noncurrent versions and incomplete multipart uploads.
  - A test asserts each rule.
- **DynamoDB with temporary rows:** enable TTL on an expiry attribute.
- **A UI with a theme or a second language:**
  - Theme button: three states in one cycle (browser setting, light, dark). The browser setting is the default and removes the stored choice, so a visitor can return to it. The icon and the `aria-label` show the current state. Set it from the stored choice in the head, before first paint.
  - Two languages: the nav link goes to the same page in the other language, labelled with the target code (`DE` on the English page). No dropdown. A third language brings the menu back.

## Agent files

- `AGENTS.md` holds the rules. Claude Code reads only `CLAUDE.md`, so `CLAUDE.md` imports it with `@AGENTS.md`. Sections: AWS, Code rules, Tests, Process, Design (only if the repo has a UI).
- Reference a standard and stop. State only the choice, the exception, the project fact.
- Each rule is a bullet with its reason when the reason is not obvious.
- A rule that a test or a task can enforce goes into the test or the task. Make wiring structural.
- Keep no rule in `CLAUDE.md`.
- Use the latest LTS of each runtime (Node, `@types/node`, `engines`, the Lambda runtime) and the latest stable Go. Renovate keeps the libraries current. Pulumi needs `typescript@5`.
- Account IDs and the `source assume` line belong in the agent file.
- Customer-facing and legal copy names no provider and no AWS service, and states no margin, factor or cost split. Exceptions: the pay step, the legal pages and the privacy notice.
- A retention time that the privacy notice states must match every place that enforces it. See "Conditional aspects".

## Docs

- `README.md`: environments table with accounts and domains, dev commands, deploy steps, layout, diagrams in Mermaid.
- `TODO.md`: unordered `-` bullets, per-topic headline, "Open" with options and a recommendation. Delete a done item.
- `KNOWN-ISSUES.md`: accepted gaps. A gap with a planned fix stays in `TODO.md`.
- `infra/README.md` (`templates/infra-README.md`): file layout, stack config, cost controls, DNS split. `infra/bootstrap/README.md` (`templates/bootstrap-README.md`): why it is separate, one stack per account, commands.
- `docs/runbooks/first-deploy.md` (`templates/first-deploy.md`): phases with a check each, and "When it fails". Keep the README short and link it.
- Code comments: why only, two lines max, no history.

## Alignment check

Run when the user asks to align, or after a change to the shared setup. Compare both ways, then derive rules.

1. Read the sibling repos (`mosswood-app`, `sendpdf`, and this repo): agent file, Taskfile, `infra/` projects and `Pulumi*.yaml`, `.gitignore`, lint config, dependency bot, CI files, `TODO.md`, `KNOWN-ISSUES.md`, docs, skills, branches (`git branch --merged`).
2. List each difference. Mark it "product specific" or "align".
3. For each "align", ask which side is better and why. Decide: easier, safer, less code, or more complete.
4. The better side wins. Change the other side. Put the new rule into this skill and, when it is a file, into `templates/`.
5. A rule that one repo has and the skill lacks goes into the skill. A rule of the skill that no repo follows is wrong or the repo is behind: fix one.
6. Check each repo: markdown lint exits 0, `task verify` passes. Do not commit work of someone else that sits in the tree.
7. Delete merged branches. Report the differences and the decisions to the user.
