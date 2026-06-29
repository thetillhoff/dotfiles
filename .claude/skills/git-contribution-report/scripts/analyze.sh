#!/usr/bin/env bash
# git-contribution-report :: analyze.sh
# Aggregate git contributions across many repos, merging multiple
# names/emails into one identity so a person's work sums up even when
# they committed under different addresses in different repos.
#
# Pure bash + git. No Python, no jq. Works on macOS bash 3.2.
set -u
set -f   # stop the shell expanding ** — git pathspecs need the literal glob

usage(){ cat >&2 <<'U'
Usage:
  analyze.sh list-authors <root> [maxdepth]
      List every author "Name|email" with commit counts across all repos
      under <root>. Run this FIRST to discover which addresses belong to
      whom, then build the identity config from it.

  analyze.sh report <root> <people.conf> [maxdepth]
      Emit JSON: per-person aggregated stats, team totals, share of all
      commits, monthly activity, and per-repo workstreams.

  analyze.sh selftest
      Build a throwaway repo with a person who committed under two emails
      and assert the identity merge sums correctly.

people.conf format (one person per block; each line is an author-match
regex, matched case-insensitively against "Name <email>" by git --author
--perl-regexp). Group every address a person used under one [Name]:

  [Alice Smith]
  alice@work\.com
  alice@personal\.com
  asmith
  [Bob Jones]
  bob\.jones

  # lines starting with # are comments

EXCLUDES env var (space-separated git pathspecs) overrides the default
generated-file exclusions used for line counts.
U
exit 1; }

# ---- generated-file exclusions for line counts (override via $EXCLUDES) ----
if [ -n "${EXCLUDES:-}" ]; then
  read -r -a EX <<< "$EXCLUDES"
else
  EX=(
    ':(exclude,glob)**/*.lock'
    ':(exclude,glob)**/*-lock.json'
    ':(exclude,glob)**/*.sum'
    ':(exclude,glob)**/cdk.out/**'
    ':(exclude,glob)**/vendor/**'
    ':(exclude,glob)**/node_modules/**'
    ':(exclude,glob)**/dist/**'
    ':(exclude,glob)**/build/**'
    ':(exclude,glob)**/*.min.*'
    ':(exclude,glob)**/*.svg'
    ':(exclude,glob)**/*.png'
    ':(exclude,glob)**/*.jpg'
    ':(exclude,glob)**/*.map'
    ':(exclude,glob)**/*.snap'
    ':(exclude,glob)**/*.pdf'
  )
fi

# .git can be a dir (normal) or a file (worktree/submodule) — match both.
find_repos(){ find "$1" -maxdepth "${2:-3}" -name .git \( -type d -o -type f \) 2>/dev/null \
                | sed 's#/\.git$##' | sort; }

# git log --all already de-duplicates a commit reachable from several refs,
# so no extra sort -u is needed for counts or numstat.
count(){ ( cd "$1" && git log --all --no-merges --perl-regexp -i --author="$2" --format='%H' 2>/dev/null ) | grep -c .; }
mergecount(){ ( cd "$1" && git log --all --merges --perl-regexp -i --author="$2" --format='%H' 2>/dev/null ) | grep -c .; }
firstdate(){ ( cd "$1" && git log --all --perl-regexp -i --author="$2" --format='%ad' --date=short 2>/dev/null ) | sort | head -1; }
lastdate(){  ( cd "$1" && git log --all --perl-regexp -i --author="$2" --format='%ad' --date=short 2>/dev/null ) | sort | tail -1; }

# numstat: skip the "-\t-\t" binary rows and any non-numeric lines.
addremove(){ ( cd "$1" && git log --all --no-merges --perl-regexp -i --author="$2" \
                 --numstat --format='' -- . "${EX[@]}" 2>/dev/null ) \
             | awk 'NF==3 && $1 ~ /^[0-9]+$/ {a+=$1; d+=$2} END{printf "%d %d", a+0, d+0}'; }

readme_purpose(){ local f
  for f in README.md README README.txt readme.md docs/README.md; do
    if [ -f "$1/$f" ]; then
      head -8 "$1/$f" | grep -vE '^[[:space:]]*$|^#+[[:space:]]*$' | head -1 \
        | sed 's/^#* *//; s/ *$//'
      return
    fi
  done
}

jesc(){ printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }

# Parse people.conf into parallel arrays NAMES[] and RES[] (regex per person,
# patterns joined with |). Indexed arrays, not assoc — bash 3.2 safe.
parse_conf(){
  NAMES=(); RES=()
  local line i
  while IFS= read -r line || [ -n "$line" ]; do
    line="${line%$'\r'}"
    case "$line" in
      ''|\#*) : ;;
      \[*\])
        line="${line#[}"; NAMES+=("${line%]}"); RES+=("") ;;
      *)
        i=$(( ${#NAMES[@]} - 1 ))
        [ "$i" -lt 0 ] && { echo "pattern before any [Name]: $line" >&2; exit 1; }
        if [ -z "${RES[$i]}" ]; then RES[$i]="$line"; else RES[$i]="${RES[$i]}|$line"; fi ;;
    esac
  done < "$1"
  [ "${#NAMES[@]}" -gt 0 ] || { echo "no people defined in config" >&2; exit 1; }
}

list_authors(){
  [ -n "${1:-}" ] || usage
  local repos; repos=$(find_repos "$1" "${2:-3}")
  [ -n "$repos" ] || { echo "no git repos under $1" >&2; exit 1; }
  while IFS= read -r r; do ( cd "$r" && git log --all --format='%an|%ae' 2>/dev/null ); done <<< "$repos" \
    | sort | uniq -c | sort -rn
}

report(){
  [ -n "${1:-}" ] && [ -n "${2:-}" ] || usage
  local root="$1" depth="${3:-3}" repos r c tc i re a d m f l rb
  parse_conf "$2"
  repos=$(find_repos "$root" "$depth")
  [ -n "$repos" ] || { echo "no git repos under $root" >&2; exit 1; }

  # team regex = every person's patterns joined
  local teamre=""
  for i in "${!RES[@]}"; do
    [ -z "${RES[$i]}" ] && continue
    if [ -z "$teamre" ]; then teamre="${RES[$i]}"; else teamre="$teamre|${RES[$i]}"; fi
  done

  local all_commits=0 team_commits=0
  while IFS= read -r r; do
    c=$( ( cd "$r" && git log --all --no-merges --format='%H' 2>/dev/null ) | grep -c . )
    all_commits=$(( all_commits + c ))
    team_commits=$(( team_commits + $(count "$r" "$teamre") ))
  done <<< "$repos"

  # per-person aggregation
  local people_json=""
  for i in "${!NAMES[@]}"; do
    re="${RES[$i]}"; [ -z "$re" ] && continue
    local pc=0 pa=0 pd=0 pm=0 pfirst="9999-12-31" plast="0000-00-00" repobd=""
    while IFS= read -r r; do
      c=$(count "$r" "$re"); [ "$c" -eq 0 ] && continue
      read a d < <(addremove "$r" "$re")
      m=$(mergecount "$r" "$re"); f=$(firstdate "$r" "$re"); l=$(lastdate "$r" "$re")
      pc=$((pc+c)); pa=$((pa+a)); pd=$((pd+d)); pm=$((pm+m))
      [[ "$f" < "$pfirst" ]] && pfirst="$f"
      [[ "$l" > "$plast"  ]] && plast="$l"
      rb=$(basename "$r")
      repobd="$repobd{\"repo\":\"$(jesc "$rb")\",\"commits\":$c},"
    done <<< "$repos"
    people_json="$people_json{\"name\":\"$(jesc "${NAMES[$i]}")\",\"commits\":$pc,\"added\":$pa,\"removed\":$pd,\"merges\":$pm,\"first\":\"$pfirst\",\"last\":\"$plast\",\"repos\":[${repobd%,}]},"
  done
  people_json="[${people_json%,}]"

  # workstreams: every repo the team touched, with purpose and who
  local ws_json="" who purpose
  while IFS= read -r r; do
    tc=$(count "$r" "$teamre"); [ "$tc" -eq 0 ] && continue
    who=""
    for i in "${!NAMES[@]}"; do
      re="${RES[$i]}"; [ -z "$re" ] && continue
      [ "$(count "$r" "$re")" -gt 0 ] && who="$who\"$(jesc "${NAMES[$i]}")\","
    done
    purpose=$(readme_purpose "$r")
    ws_json="$ws_json{\"repo\":\"$(jesc "$(basename "$r")")\",\"purpose\":\"$(jesc "$purpose")\",\"team_commits\":$tc,\"people\":[${who%,}]},"
  done <<< "$repos"
  ws_json="[${ws_json%,}]"

  # monthly team activity
  local monthly_json="" cnt mon
  while read -r cnt mon; do
    [ -z "${mon:-}" ] && continue
    monthly_json="$monthly_json\"$mon\":$cnt,"
  done <<< "$( while IFS= read -r r; do ( cd "$r" && git log --all --no-merges --perl-regexp -i --author="$teamre" --format='%ad' --date=format:'%Y-%m' 2>/dev/null ); done <<< "$repos" | sort | uniq -c )"
  monthly_json="{${monthly_json%,}}"

  local share
  share=$(awk "BEGIN{ if($all_commits>0) printf \"%.1f\", $team_commits*100/$all_commits; else print 0 }")

  cat <<JSON
{
  "generated": "$(date +%F)",
  "root": "$(jesc "$root")",
  "totals": { "all_commits": $all_commits, "team_commits": $team_commits, "team_share_pct": $share },
  "people": $people_json,
  "workstreams": $ws_json,
  "monthly_team": $monthly_json
}
JSON
}

selftest(){
  local t; t=$(mktemp -d)
  (
    cd "$t" && git init -q && git symbolic-ref HEAD refs/heads/main
    git -c user.email=a@x.com -c user.name=Alice commit -q --allow-empty -m c0
    printf 'l1\nl2\nl3\n' > f.txt
    git add f.txt && git -c user.email=a@x.com -c user.name=Alice commit -qm one
    printf 'x\n' >> f.txt && git -c user.email=b@y.com -c user.name=Bob commit -qam two
    # same person, different email — must merge into Alice
    printf 'y\n' >> f.txt && git -c user.email=alice@other.com -c user.name="Alice A" commit -qam three
  )
  cat > "$t/people.conf" <<C
[Alice]
a@x\.com
alice@other\.com
[Bob]
b@y\.com
C
  local out; out=$(report "$t" "$t/people.conf")
  echo "$out"
  echo "$out" | grep -q '"name":"Alice","commits":3' || { echo "FAIL: Alice should sum to 3 across two emails" >&2; rm -rf "$t"; exit 1; }
  echo "$out" | grep -q '"name":"Bob","commits":1'   || { echo "FAIL: Bob should be 1" >&2; rm -rf "$t"; exit 1; }
  rm -rf "$t"
  echo "selftest OK"
}

case "${1:-}" in
  list-authors) shift; list_authors "$@" ;;
  report)       shift; report "$@" ;;
  selftest)     selftest ;;
  *)            usage ;;
esac
