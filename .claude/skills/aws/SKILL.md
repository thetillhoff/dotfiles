---
name: aws
description: >
  IAM policy patterns and AWS best practices. Use when writing or reviewing
  IAM policies, CloudFormation IAM resources, KMS key policies, or any AWS
  permission/condition configuration. Also use to diagnose a failing Lambda app
  (generic error page, Cognito or IAM denial) and to write CloudFront Functions.
---

## IAM Condition Keys

**Set-valued keys require `ForAnyValue:` prefix** — single-value operators (`StringEquals`, `ArnLike`, etc.) silently fail on set-valued keys.

Common set-valued keys:
- `kms:ResourceAliases` → `ForAnyValue:StringEquals`
- `aws:TagKeys` → `ForAnyValue:StringEquals`
- `aws:RequestTag` when multi-valued → `ForAnyValue:StringEquals`
- `sts:TransitiveTagKeys` → `ForAnyValue:StringEquals`

```yaml
# Wrong — silently matches nothing
Condition:
  StringEquals:
    "kms:ResourceAliases": "alias/my-key"

# Correct
Condition:
  "ForAnyValue:StringEquals":
    "kms:ResourceAliases": "alias/my-key"
```

## KMS Cross-Account Sharing

To share a CMK-encrypted snapshot/AMI cross-account, the **source account role** needs:

```yaml
- kms:DescribeKey
- kms:CreateGrant       # lets EC2 use the key on behalf of the target
- kms:ReEncrypt*
```

Condition to scope to a specific key by alias:

```yaml
Condition:
  "ForAnyValue:StringEquals":
    "kms:ResourceAliases": "alias/<key-alias>"
```

AWS-managed keys (`aws/ebs`, etc.) **cannot** be shared cross-account — always use a CMK.

## EC2 Packer AMI Build (encrypt_boot)

When `encrypt_boot = true`, Packer calls `ec2:CopyImage` in the **build account** (not just destination accounts). Add it to the builder role alongside `ec2:CreateImage`.

## Least Privilege Patterns

- Scope KMS by alias condition rather than key ARN — survives key rotation.
- Scope EC2 by `aws:RequestedRegion` to prevent unintended cross-region actions.
- Use `aws:ResourceAccount` on cross-account trust policies to prevent confused deputy.

## Read-only diagnosis of a Lambda app

- `aws logs filter-log-events --log-group-name /aws/lambda/<fn>` shows the real error behind a generic page message. A missing IAM action looks like "could not ...".
- CloudTrail `lookup-events` shows why a Cognito call failed.
- `aws iam simulate-principal-policy` shows what a Lambda role may do.
- `aws cloudfront test-function` runs a viewer-request Function on the real runtime.
- `aws logs tail` has no `--until`. For a time window use `filter-log-events` with `--start-time $(date -d <ISO time> +%s)000` and `--end-time`. In a command for the user, set `export AWS_PAGER=` first, or the pager hides the output.
- An API Gateway 5xx alarm with `Errors` and `Throttles` at 0 on the function means the function itself answered 5xx (a deliberate 503 such as maintenance mode) or API Gateway rejected the response. The built-in `5xx` metric has no path and no status split: turn on the access log of the stage.

## CloudFront Functions are not Node

They run on `cloudfront-js-2.0`. A Node test does not prove that the code compiles there: the runtime rejects `catch {}` without a binding.
