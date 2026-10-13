# Release notes from GitHub

## A release has no body

Some projects (for example `tailscale/tailscale`) publish empty releases. Read the commit list between the two tags instead. Filter it for the component you run:

```sh
gh api repos/<owner>/<repo>/compare/<old-tag>...<new-tag> --paginate \
  -q '.commits[].commit.message | split("\n")[0]' > commits.txt
grep -i '<component>\|breaking\|remove\|deprecat' commits.txt
```

Then check each hit against your values and config. Run `gh release list -R <owner>/<repo>` first, because tags can skip numbers.

## A chart has its own changelog

A Helm chart can ship in the app repo with its own `CHANGELOG.md` and an empty release body (for example `metrics-server`). Read the raw file:

```sh
curl -s https://raw.githubusercontent.com/<owner>/<repo>/master/charts/<chart>/CHANGELOG.md
```

## Chart version against app version

```sh
helm repo add <name> <url> && helm repo update <name>
helm search repo <name>/<chart> -l
```

The `APP VERSION` column shows the app of each chart version.

## Does an env var or flag still exist

Fetch the source at the new tag and grep it:

```sh
curl -s https://raw.githubusercontent.com/<owner>/<repo>/<tag>/<path> | grep -n '<NAME>'
```
