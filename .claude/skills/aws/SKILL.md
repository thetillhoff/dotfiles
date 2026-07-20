---
name: aws
description: >
  IAM policy patterns and AWS best practices. Use when writing or reviewing
  IAM policies, CloudFormation IAM resources, KMS key policies, or any AWS
  permission/condition configuration.
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
