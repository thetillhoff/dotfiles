#!/usr/bin/env bash
# Reports what this repo needs for an architecture-audit and what's actually here.
# Run from the repo root BEFORE spawning any agent: a missing runtime changes the
# plan (agents read instead of parsing = slower, more tokens), and a missing
# reachability tool weakens Phases 2-3. Diagnostic only - installs nothing.
set -uo pipefail
skill="$(cd "$(dirname "$0")/.." && pwd)"
ask=0

files() { git ls-files "$@" 2>/dev/null | grep -vE 'node_modules|/vendor/|\.min\.' | wc -l | tr -d ' '; }
have() { command -v "$1" >/dev/null 2>&1; }
row() { printf '  %-14s %s\n' "$1" "$2"; }
need() { ask=1; printf '  %-14s MISSING - %s\n' "$1" "$2"; }

n_py=$(files '*.py')
n_go=$(files '*.go')
n_ts=$(files '*.ts' '*.tsx' '*.js' '*.jsx')
# Only other *code*, not docs/config: an extractor gap matters, a .md file doesn't.
n_other=$(files '*.rs' '*.java' '*.kt' '*.rb' '*.cs' '*.swift' '*.php' '*.c' '*.cc' '*.cpp' '*.h' '*.hpp' '*.sh' '*.bash' '*.scala' '*.ex' '*.exs')

echo "repo: $(basename "$PWD")  ·  py=$n_py go=$n_go ts/js=$n_ts other=$n_other"
echo

if [ "$n_py" -gt 0 ]; then
  echo "python"
  if have docker; then
    row harvest "ok (python:3-slim + scripts/extract_py.py, stdlib only)"
    row reachability "ok on demand (vulture/pyflakes inside the same container)"
  elif have python3; then
    row harvest "ok via host python3 - stdlib only, but check the repo's Docker convention"
    need vulture "no docker: pip on the host is not allowed, so reachability is grep-only"
  else
    need python3/docker "neither found - Phase 1 falls back to agents reading .py files"
  fi
fi

if [ "$n_go" -gt 0 ]; then
  echo "go"
  have go && row harvest "ok (scripts/go, stdlib go/ast)" ||
    need go "no toolchain - Phase 1 falls back to agents reading .go files"
  if have go; then
    have deadcode && row reachability "ok (deadcode)" ||
      need deadcode "go install golang.org/x/tools/cmd/deadcode@latest  (else go vet + rg only)"
  fi
fi

if [ "$n_ts" -gt 0 ]; then
  echo "typescript/js"
  if ! have node; then
    need node "Phase 1 falls back to agents reading .ts/.tsx files"
  else
    # Resolution is per package in a monorepo, so report each project that has a
    # manifest - but a package only OWNS the sources no nested package claims first,
    # otherwise a root manifest holding only lint deps looks like the TS project.
    pkgdirs="$(mktemp)"
    trap 'rm -f "$pkgdirs"' EXIT
    git ls-files '*package.json' | grep -v node_modules | xargs -n1 dirname | sort -u >"$pkgdirs"
    while read -r dir; do
      owned=$(git ls-files "$dir" | grep -E '\.(ts|tsx|js|jsx)$' | grep -v node_modules |
        awk -v self="$dir" 'NR==FNR { if ($0 != self && $0 != ".") d[$0]; next }
          { keep = 1
            for (p in d) if (index($0, p "/") == 1) keep = 0
            if (keep) n++ }
          END { print n + 0 }' "$pkgdirs" -)
      [ "$owned" = 0 ] && continue
      if (cd "$dir" && node -e 'require.resolve("typescript",{paths:[process.cwd()]})' 2>/dev/null); then
        row "harvest $dir" "ok ($owned files)"
      else
        need "harvest $dir" "$owned files, no node_modules/typescript - 'cd $dir && npm install'"
      fi
    done <"$pkgdirs"
    row reachability "npx knip / ts-prune / madge download on demand - needs network + your ok"
  fi
fi

if [ "$n_other" -gt 0 ]; then
  echo "other languages"
  row harvest "$n_other file(s) have no bundled extractor - agents read them (slower, same output)"
fi

echo
have rg || need rg "every 'is this dead' confirmation grep gets slower without ripgrep"
have git || need git "the whole inventory is git ls-files"

echo
if [ "$ask" = 1 ]; then
  cat <<'MSG'
Ask the user once, listing the MISSING lines above with their install commands, then
either wait for the install or proceed degraded on their say-so. Don't install anything
yourself, and don't silently proceed: a missing extractor multiplies Phase-1 token cost,
and a missing reachability tool means dead-code findings rest on greps alone - the user
should get to decide which they'd rather pay.
MSG
else
  echo "all set - nothing to install, proceed to the inventory."
fi
