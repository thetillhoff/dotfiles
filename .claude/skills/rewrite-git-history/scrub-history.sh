#!/bin/sh
# Builds the branch <current>-scrubbed: the commits of the current branch after BASE, with text replaced in some files.
# Usage: scrub-history.sh <base> <rules-file>
#   base        commit before the first commit to rewrite (for example `189e857^`)
#   rules-file  one line per file: <path><TAB><sed-script-file>
# Env PATTERN: extended regex of the old text. Every rewritten commit must not match it (binary files are skipped).
# It moves no branch and deletes nothing.
set -eu
BASE=$(git rev-parse "$1")
RULES=$(realpath "$2")
CUR=$(git branch --show-current)
NEW=$CUR-scrubbed
[ -z "$(git status --porcelain)" ] || { echo "working tree not clean"; exit 1; }
[ -z "$(git rev-list --merges "$BASE..$CUR")" ] || { echo "merge commit in range"; exit 1; }
IDX=$(mktemp -u)
trap 'rm -f "$IDX"' EXIT
PARENT=$BASE
for c in $(git rev-list --reverse "$BASE..$CUR"); do
  export GIT_INDEX_FILE=$IDX
  git read-tree "$c"
  while IFS="$(printf '\t')" read -r path sedfile; do
    git cat-file -e "$c:$path" 2>/dev/null || continue
    mode=$(git ls-tree "$c" -- "$path" | cut -d' ' -f1)
    blob=$(git show "$c:$path" | sed -f "$sedfile" | git hash-object -w --stdin)
    git update-index --cacheinfo "$mode,$blob,$path"
  done < "$RULES"
  tree=$(git write-tree)
  unset GIT_INDEX_FILE
  export GIT_AUTHOR_NAME="$(git log -1 --format=%an "$c")" GIT_AUTHOR_EMAIL="$(git log -1 --format=%ae "$c")" GIT_AUTHOR_DATE="$(git log -1 --format=%aI "$c")"
  export GIT_COMMITTER_NAME="$(git log -1 --format=%cn "$c")" GIT_COMMITTER_EMAIL="$(git log -1 --format=%ce "$c")" GIT_COMMITTER_DATE="$(git log -1 --format=%cI "$c")"
  PARENT=$(git cat-file commit "$c" | sed '1,/^$/d' | git commit-tree "$tree" -p "$PARENT")
done
git branch -f "$NEW" "$PARENT"
echo "$NEW = $PARENT ($(git rev-list --count "$BASE..$PARENT") commits)"
fmt='%an|%ae|%aI|%cI|%s'
[ "$(git log --format="$fmt" "$BASE..$CUR")" = "$(git log --format="$fmt" "$BASE..$NEW")" ] && echo "OK: author, dates and subjects are identical"
git diff --quiet "$CUR" "$NEW" && echo "OK: the tip has the same content as $CUR" || echo "CHECK: the tip differs from $CUR (clean the tip in a commit first)"
bad=0
for n in $(git rev-list "$BASE..$NEW"); do
  if git grep -q -I -E "$PATTERN" "$n" --; then echo "old text in $n: $(git grep -l -I -E "$PATTERN" "$n" -- | sed 's/^[0-9a-f]*://' | tr '\n' ' ')"; bad=1; fi
done
[ $bad = 0 ] && echo "OK: no old text in any rewritten commit"
exit $bad
