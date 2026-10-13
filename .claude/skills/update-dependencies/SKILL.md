---
name: update-dependencies
description: >
  Update all dependencies of the current project to the latest versions, in any language or framework.
  Detects the package managers, applies every non-major update, tests, then tries each major bump alone
  and asks the user about the ones that break. Use whenever the user says "update dependencies",
  "update deps", "bump packages", "upgrade everything", "what is outdated", "renovate this by hand",
  or wants Dockerfile base images, GitHub Actions or lockfiles brought up to date.
---

# Update dependencies

Goal: the newest versions that still pass the tests, with the least questions to the user.

## 1. Prepare

- Run `git branch --show-current`, `git status`, then `git pull`. Stop if the tree has uncommitted changes the user did not mention.
- Find the ecosystems by their manifests (`go.mod`, `package.json`, `Cargo.toml`, `pyproject.toml`, `requirements*.txt`, `Gemfile`, `composer.json`, `pom.xml`, `build.gradle*`, `*.csproj`, `Dockerfile*`, `.github/workflows/*`, `.pre-commit-config.yaml`, `Taskfile.yml`, `.tool-versions`). Search subdirectories too: monorepos hold several.
- Find the test command: the project docs (`AGENTS.md`, `CLAUDE.md`, `README`), `Taskfile`, `Makefile`, or the ecosystem default. Run it now. A red baseline means: tell the user and stop. Without tests, use the build or type check as the gate and say so.
- Follow the project rules for the toolchain. Python runs in Docker, never on the host. Use `cd <path> && <cmd>`, never a flag that changes the directory.

## 2. Find the updates

Use the standard tool of each ecosystem. Prefer a tool that is already installed or in the project. Run it through `npx` or a container if it is missing.

| Ecosystem | Outdated list | Non-major update | Major update |
| --- | --- | --- | --- |
| Go | `go list -u -m -json all` | `go get -u ./... && go mod tidy` | `go get <mod>@latest` (a `/vN` path change needs an import rewrite) |
| npm / pnpm / yarn | `npm outdated --json` | `npx npm-check-updates -u --target minor` then install | `npx npm-check-updates -u --filter <pkg>` then install |
| Rust | `cargo outdated` or `cargo update --dry-run` | `cargo update` | edit the version in `Cargo.toml` (`cargo upgrade --incompatible` if `cargo-edit` exists) |
| Python | `pip list --outdated`, `uv lock --upgrade --dry-run`, `poetry show --outdated` | `uv lock --upgrade`, `poetry update` | edit the constraint, then re-lock |
| Ruby | `bundle outdated` | `bundle update --minor` | edit the `Gemfile`, `bundle update <gem>` |
| PHP | `composer outdated` | `composer update` | `composer require <pkg>:^N` |
| Java / .NET | `mvn versions:display-dependency-updates`, `gradle dependencyUpdates`, `dotnet list package --outdated` | the matching update goal or `dotnet add package` | same, with the new version |
| Docker | the tag of each `FROM` line against the registry | newest tag of the same major, same variant (`-slim`, `-alpine`) | newest major tag |
| GitHub Actions | the `uses:` refs | newest tag of the same major | newest major tag |
| pre-commit | `pre-commit autoupdate` | same | same |
| Pulumi / Terraform providers | the ecosystem rows above (Pulumi) or `terraform init -upgrade` | same | edit the version |

Respect deliberate pins: a comment, an upper bound, an `exclude`, or a pin in the docs. Do not remove them. List them in the report.

Runtimes and their type packages (Node, Python, Go toolchain, JDK, Lambda runtimes, base images, `@types/node`) go only up to the newest LTS or long-support release. Never update to a non-LTS release. Do not ask about it and do not list it as a breaking major. Skip it, with one line in the report.

## 3. Apply, test, commit

1. **Non-major first.** Update all minor and patch versions, one ecosystem at a time. Run the gate after each ecosystem. Commit each green ecosystem on its own. A version that SemVer does not protect is not non-major: treat it as a major and read its release notes first (see "Release notes"). That covers `0.x` versions, `v1.<minor>` cloud-native versions, and a Helm chart whose `appVersion` is one of these.
2. **A non-major update breaks the gate.** Bisect: revert half of the packages, find the culprit, hold it back at the last good version. Continue with the rest.
3. **Then the majors, one package at a time.** Bump one, fix the compile errors that need no design decision (renamed imports, moved symbols), run the gate. Green: commit it. Red: restore the file copy of step 1 and collect the failure. Related packages that must move together (a framework and its plugins) count as one.
4. Restore with a file copy taken before the bump. Never use `git checkout` on files with uncommitted work.
5. Run the audit tool after the updates (`npm audit`, `govulncheck ./...`, `cargo audit`, `pip-audit`, `bundle audit`). Report what is left.

Done when: every outdated package is updated, held back with a reason, or in the list for the user. Run the outdated command again to prove it.

### Release notes

Find the release notes before you bump a major. Do the same for every version that SemVer does not protect:

- **`0.x`:** any bump, even a patch, can break. Read the notes.
- **`v1.<minor>`** (Kubernetes, Talos, Cilium, Longhorn, Flux): a minor is the breaking step.
- **Helm charts:** the chart version is not the app version. Compare `appVersion` old and new (`helm search repo <chart> -l`). A chart `1.x` can ship an app `0.x`, and an annotation, flag or default of the app can change without a chart major. A change that a chart renders without error is not proof.

Read the notes of each version between old and new, not only the target. Look for renamed flags, annotations and defaults, and for "breaking" sections. `helm template` and the gate only show that it renders, not that it behaves the same. Sources, in order: the `CHANGELOG` or `docs/` of the repo, GitHub releases (`gh release list` and `gh release view <tag> -R <owner>/<repo>`), the project's upgrade guide, then the package registry page. When a release has no body, or you need the chart `appVersion`, see `references/github-release-notes.md`. Some stateful systems (Longhorn, databases, etcd) allow one minor at a time: plan every step.

Ask the user whether to save the approach next to the skill (`references/<topic>.md`) when:

- a source was hard to find, or
- you needed a command or a script for GitHub, GitLab or a registry (it is likely needed again).

Do not save it without an answer.

## 4. Test that it works

A green gate is not enough. After the updates, prove that the system still works as deployed, not only that it builds. Do this for every ecosystem, at the end of each step the user can roll out:

- Deploy or run it the way the project does (for example `pulumi preview` and `pulumi up` from local, a Flux reconcile, `docker compose up`, a playbook run). Ask before you touch live infrastructure.
- Check the live result: pods and services are healthy, endpoints answer, logs show no new errors. Verify the behavior, not only the config.
- Name what you could not test. If a step needs the user to roll it out, say so and stop there.

## 5. Report and ask

Show a short table: updated, held back (pinned), and breaking majors. Always write versions as `old -> new` (for example `cert-manager v1.20.1 -> v1.21.2`), never the target alone. For each breaking major give the package, the versions, the first error, and a link to the changelog or migration guide.

Then ask the user how to continue with each breaking major. Offer: migrate now (the code changes, with a size estimate), stay on the latest minor and record it in `TODO.md`, or pin it with a reason. Do not migrate without an answer: a major bump often needs a design decision.

## 6. Finish

- Update docs that name versions (`README`, `CHANGELOG` if the repo keeps one). Add the deferred majors to `TODO.md`.
- Commit with `git commit -F - <<'MSG'`, stage by path, run `git branch --show-current` first. Do not push unless the user asks.
