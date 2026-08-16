#!/usr/bin/env bash
# Runs each extractor against a fixture and asserts the rows it must produce.
# Skips a language whose runtime isn't installed - a missing toolchain is not a
# failure, a wrong row is. Run from anywhere.
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
fail=0

check() { # check <label> <expected-substring> <<< output
  local label="$1" want="$2" out
  out="$(cat)"
  if grep -qF -- "$want" <<<"$out"; then
    echo "ok   $label"
  else
    echo "FAIL $label: missing '$want'"
    echo "$out" | sed 's/^/       /'
    fail=1
  fi
}

# --- python (stdlib ast; Docker per dev-environment, host python3 only as fallback)
if command -v docker >/dev/null; then
  docker run --rm -i -v "$work:/w:z" -w /w python:3-slim python - --selftest \
    <"$here/extract_py.py" | check "python" "extract_py selftest ok"
elif command -v python3 >/dev/null; then
  echo "note python: no docker, using host python3 (stdlib only, installs nothing)"
  python3 "$here/extract_py.py" --selftest | check "python" "extract_py selftest ok"
else
  echo "skip python: no docker and no python3"
fi

# --- go
if command -v go >/dev/null; then
  cat >"$work/f.go" <<'GO'
package p

// Broker places orders.
type Broker interface {
	// Place sends one order.
	Place(id string, qty int) error
}

type wallet struct{}

// Cash returns free cash.
func (w *wallet) Cash(ccy string) (float64, error) { return 0, nil }
GO
  out="$(cd "$here/go" && go run . "$work/f.go" 2>&1)"
  check "go interface" $'\tinterface\tpub\tBroker\t\tBroker places orders.' <<<"$out"
  check "go iface-method" $'\tiface-method\tpub\tBroker.Place\t(id string, qty int) error\tPlace sends one order.' <<<"$out"
  check "go method" $'\tmethod\tpub\twallet.Cash\t(ccy string) (float64, error)\tCash returns free cash.' <<<"$out"
  check "go struct vis" $'\tstruct\tpriv\twallet\t\t-' <<<"$out"
else
  echo "skip go: no go toolchain"
fi

# --- typescript
if command -v node >/dev/null && node -e 'require.resolve("typescript",{paths:[process.cwd()]})' 2>/dev/null; then
  ts_from="$PWD"  # the extractor resolves typescript from cwd, so cwd must be the TS project
else
  ts_from=""
  echo "skip typescript: node or typescript not resolvable (run from a dir with node_modules/typescript)"
fi
if [ -n "$ts_from" ]; then
  cat >"$work/f.ts" <<'TS'
/** Holds cash. */
export class Wallet {
  /** Free cash in the base currency. */
  public cash(ccy: string): number { return 0; }
  private _fee(): number { return 0; }
}
/** Places one order. */
export const place = async (id: string, qty = 1): Promise<void> => {};
export interface Broker { place(id: string): Promise<void>; }
TS
  out="$(cd "$ts_from" && node "$here/extract_ts.js" "$work/f.ts" 2>&1)"
  check "ts class" $'\tclass\tpub\tWallet\t\tHolds cash.' <<<"$out"
  check "ts method" $'\tmethod\tpub\tWallet.cash\t(ccy: string)->number\tFree cash in the base currency.' <<<"$out"
  check "ts private" $'\tmethod\tpriv\tWallet._fee\t()->number\t-' <<<"$out"
  check "ts arrow const" $'\tfunc\tpub\tplace\t(id: string, qty = 1)->Promise<void>\tPlaces one order.' <<<"$out"
  check "ts iface-method" $'\tiface-method\tpub\tBroker.place\t(id: string)->Promise<void>' <<<"$out"
fi

[ "$fail" = 0 ] && echo "all extractor selftests passed"
exit "$fail"
