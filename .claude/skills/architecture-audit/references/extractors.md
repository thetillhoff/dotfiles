# Extractors

`bash scripts/preflight.sh` (from the repo root) answers "what's here and what's
missing" for everything below, in one pass. Run it before reading further.

Two different jobs. Don't conflate them: **symbol harvest** is mechanical and
bundled here; **reachability** needs whole-repo analysis and borrows whatever the
repo already has installed.

## 1. Symbol harvest (bundled, `scripts/`)

Emits TSV `path · line · kind · vis · name · signature · doc` — one row per
class/func/method/interface/type. This is the half a model shouldn't spend tokens
transcribing. Agents then add `purpose` (from the body) and the
MATCH/DRIFT/MISNAMED/UNDOC verdict; the TSV says nothing about behaviour, so the
bodies still get read.

`vis`: `pub` / `priv` / `local` (module-private in TS). `kind` distinguishes
`iface-method` from `method` in both Go and TS, because an interface method is a
contract someone implements, not necessarily a call site.

| Language | Command |
| --- | --- |
| Python | `docker run --rm -i -v "$PWD:/repo:z" -w /repo python:3-slim python - $(git ls-files '*.py') < ~/.claude/skills/architecture-audit/scripts/extract_py.py` |
| Go | `cd ~/.claude/skills/architecture-audit/scripts/go && go run . <absolute paths>` |
| TS/JS | `cd <ts-project-dir> && node ~/.claude/skills/architecture-audit/scripts/extract_ts.js $(git ls-files '*.ts' '*.tsx')` |

- Python: stdlib `ast` only, so `python:3-slim` needs no install, and Docker
  keeps the `dev-environment` rule (never host python). The script is fed on
  stdin so nothing but the repo gets mounted.
- Go: runs from its own module dir (stdlib `go/ast`, no deps), so paths must be
  absolute.
- TS: resolves the repo's own `typescript` from cwd — cwd must be the project
  that has `node_modules/typescript`, and in a monorepo that's per package.
- Big trees blow the argv limit: `git ls-files '*.py' | xargs -n 400 <cmd>` and
  drop the repeated header rows.
- A parse failure becomes an `ERROR` row instead of killing the run. A cluster of
  them means a syntax dialect the parser doesn't know (older Python target, Vue
  SFC, JSX in `.js`) — read those files directly rather than trusting the gap.
- Missing language? Skip the harvest for it; the Phase-1 agent produces the same
  columns by reading. It's slower, not different.

Verify after editing a script: `bash scripts/selftest.sh` (asserts known rows per
language, skips a language whose toolchain is absent).

## 2. Reachability (borrowed, never installed)

Whole-repo call/import analysis. Feed the output to Phases 2-3, where the
cross-file view lives — a per-file reader cannot see it.

| Language | Tool | Gives | Blind to |
| --- | --- | --- | --- |
| TS/JS | `npx knip` | unused files, exports, deps | dynamic `import()`, string-keyed routes |
| TS/JS | `npx ts-prune` | unused exports | same, plus re-export barrels |
| TS/JS | `npx madge --circular src` | import cycles | runtime-only wiring |
| Python | `vulture <paths> --min-confidence 60` | unused funcs/classes/vars | decorators-as-entry-points |
| Python | `pyflakes <paths>` | unused imports/locals | anything cross-file |
| Python | `pydeps <pkg> --no-output --show-deps` | module import graph | dynamic import, `__getattr__` lazy re-export |
| Go | `go vet ./...` | suspicious constructs | dead code as such |
| Go | `deadcode ./...` (x/tools, only if present) | unreachable funcs from main | reflection, build tags |
| any | `rg -w <name>` | every textual hit | nothing — but it's per-symbol, so use it to confirm, not to sweep |

**Every one of these lies in the same direction: it over-reports dead.** Anything
a framework calls looks unreachable — HTTP routes, CLI commands (click/typer/cobra),
kopf/operator handlers, pytest fixtures and conftest hooks, celery tasks, cron
entry points, DI registrations, Go interface satisfaction, `__getattr__` lazy
exports, pydantic/dataclass hooks, plugin registries, anything reached by string
name. The bundled harvest keeps decorators in the signature column precisely so a
Phase-2 agent can spot this before believing a "dead" verdict.

So: treat every hit as a **lead**. Confirm with `rg -w` plus one framework check,
and downgrade to "reachable only from tests" when that's what the hits show —
which is still a real finding (dead in production terms), just a different one.

## 3. Edge discovery (Phase 3 input)

Boundary edges rarely appear as imports. Grep the repo's own vocabulary — pick
the patterns that match its stack rather than running all of these:

- routes: `@app.`, `@router.`, `app.get(`, `mux.Handle`, `path(`
- SQL: table names in `FROM|INTO|UPDATE|JOIN`, plus migration files
- queues/topics: publish/subscribe/produce/consume call sites and the topic strings
- k8s: CR `kind:` values, operator handler decorators, `kubectl` in scripts
- entry points: `Makefile` targets, `docker-compose.yml` services, `CronJob`
  schedules, `if __name__ == "__main__"`, `func main`, `bin/` scripts
- config: env-var names holding URLs/DSNs — they name the other end of an edge

Each hit becomes an `edge:` line. An edge with one end only is a dead-interface
candidate for Phase 3.
