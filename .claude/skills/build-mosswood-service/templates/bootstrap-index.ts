// The account baseline that infra/ needs before its first run. The state stays local (Pulumi.yaml) and holds no secrets.
import * as aws from '@pulumi/aws';
import * as pulumi from '@pulumi/pulumi';

const config = new pulumi.Config();
const accountId = aws.getCallerIdentityOutput({}).accountId;

const stateBucket = new aws.s3.Bucket('pulumi-state', {
  bucket: pulumi.interpolate`<project>-pulumi-state-${accountId}`, // bucket names are global
  forceDestroy: false,
});
new aws.s3.BucketVersioning('pulumi-state', { bucket: stateBucket.id, versioningConfiguration: { status: 'Enabled' } });
new aws.s3.BucketPublicAccessBlock('pulumi-state', {
  bucket: stateBucket.id,
  blockPublicAcls: true,
  blockPublicPolicy: true,
  ignorePublicAcls: true,
  restrictPublicBuckets: true,
});
new aws.s3.BucketServerSideEncryptionConfiguration('pulumi-state', {
  bucket: stateBucket.id,
  rules: [{ applyServerSideEncryptionByDefault: { sseAlgorithm: 'AES256' } }],
});
new aws.s3.BucketLifecycleConfiguration('pulumi-state', {
  bucket: stateBucket.id,
  // Pulumi writes a backup of the state at every run. Each backup is a current object, so the first rule never expires it.
  rules: [
    { id: 'expire-noncurrent-versions', status: 'Enabled', filter: { prefix: '' }, noncurrentVersionExpiration: { noncurrentDays: 90 } },
    { id: 'expire-state-backups', status: 'Enabled', filter: { prefix: '.pulumi/backups/' }, expiration: { days: 90 } },
  ],
});

// Every secret in the infra/ state becomes unreadable once the key is gone, so the deletion window is the maximum.
const secretsKey = new aws.kms.Key('pulumi-secrets', {
  description: 'Encrypts the Pulumi secrets of <project>',
  enableKeyRotation: true,
  deletionWindowInDays: 30,
});
// The Taskfile finds the key by this alias.
new aws.kms.Alias('pulumi-secrets', { name: 'alias/<project>-pulumi-secrets', targetKeyId: secretsKey.id });

// A new account starts at 10 concurrent executions and Lambda keeps 10 unreserved, so reserved concurrency fails until AWS raises it.
new aws.servicequotas.ServiceQuota('lambda-concurrent-executions', { serviceCode: 'lambda', quotaCode: 'L-B99A9384', value: 1000 });

new aws.uxc.AccountCustomizations('console', { accountColor: config.get('accountColor') ?? 'none' });
