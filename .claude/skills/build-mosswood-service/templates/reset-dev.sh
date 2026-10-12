#!/usr/bin/env bash
# Empty every S3 bucket and DynamoDB table of the dev stack, then re-seed the stack's own rows.
# Needs ACCOUNT and BACKEND from the Taskfile, and credentials of that account in the calling shell.
set -euo pipefail

[ "$(aws sts get-caller-identity --query Account --output text)" = "$ACCOUNT" ] \
  || { echo "Not in the dev account ($ACCOUNT)."; exit 1; }

cd infra
# Physical ids come from the stack state, so no per-project output is needed.
ids() { PULUMI_BACKEND_URL="$BACKEND" pulumi stack export --stack dev \
  | jq -r --arg t "$1" '.deployment.resources[] | select(.type == $t) | .id'; }

empty_table() {
  local table=$1 keys
  keys=$(aws dynamodb describe-table --table-name "$table" \
    --query 'join(`,`, Table.KeySchema[].AttributeName)' --output text)
  aws dynamodb scan --table-name "$table" --projection-expression "$keys" --output json \
    | jq -c '.Items[] | {DeleteRequest: {Key: .}}' \
    | jq -cs --arg t "$table" '[range(0; length; 25) as $i | .[$i:$i+25]][] | {($t): .}' \
    | while read -r batch; do
        aws dynamodb batch-write-item --request-items "$batch" >/dev/null
      done
}

for bucket in $(ids aws:s3/bucket:Bucket); do aws s3 rm "s3://$bucket" --recursive; done
for table in $(ids aws:dynamodb/table:Table); do empty_table "$table"; done

# TableItem resources: refresh sees them gone, up writes them again.
PULUMI_BACKEND_URL="$BACKEND" pulumi up --stack dev --refresh
