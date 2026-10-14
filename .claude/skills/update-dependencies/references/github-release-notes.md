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

## A chart README holds the upgrade notes

Charts of `prometheus-community` and `grafana-community` keep a section "Upgrading" (or "Upgrading Chart") in `charts/<chart>/README.md`, one block per major (`To 29.0`, `From 17.x to 18.0.0`). Read every block between old and new:

```sh
curl -s https://raw.githubusercontent.com/<org>/helm-charts/main/charts/<chart>/README.md \
  | python3 -c 'import sys;t=sys.stdin.read();i=t.find("## Upgrading");print(t[i:i+8000])'
```

Releases of these monorepos use the tag `<chart>-<version>` (for example `loki-18.0.0`). `gh release view loki-18.0.0 -R grafana-community/helm-charts` gives the PR title of the breaking change.

## Grafana breaks things in "What's new"

Since Grafana 12 the project no longer publishes a breaking-changes page. Read the section "Breaking changes" of the What's new page of the major, as Markdown:

```sh
curl -sL -H "Accept: text/markdown" https://grafana.com/docs/grafana/latest/whatsnew/whats-new-in-v13-0/
```

Grafana tags its releases `v13.2.4`, but `gh release view` needs the exact tag from `gh release list -R grafana/grafana`.

## Diff the old and the new chart with the real values

```sh
helm template <rel> <repo>/<chart> --version <old> -n <ns> -f values.yaml > old.yaml
helm template <rel> <repo>/<chart> --version <new> -n <ns> -f values.yaml > new.yaml
diff <(awk '/^kind:/{k=$2} /^  name:/&&k{print k"/"$2; k=""}' old.yaml | sort) \
     <(awk '/^kind:/{k=$2} /^  name:/&&k{print k"/"$2; k=""}' new.yaml | sort)
diff old.yaml new.yaml | grep '^[<>]' | grep -v 'helm.sh/chart\|app.kubernetes.io/version\|checksum'
```

Look for a changed StatefulSet selector or `volumeClaimTemplates` (immutable), new images, and changes in the generated app config. Python has no `yaml` module on the host, so use `awk` and `diff`.
