import * as aws from '@pulumi/aws';
import * as pulumi from '@pulumi/pulumi';

const config = new pulumi.Config();

// Budget data lags up to 24 hours, so this detects drift. The Lambda concurrency cap and the API throttle stop a runaway.
export const costBudget = new aws.budgets.Budget('monthly-cost', {
  budgetType: 'COST',
  limitAmount: config.get('monthlyBudgetUsd') ?? '20',
  limitUnit: 'USD',
  timeUnit: 'MONTHLY',
  notifications: [80, 100].map((threshold) => ({
    comparisonOperator: 'GREATER_THAN',
    threshold,
    thresholdType: 'PERCENTAGE',
    notificationType: 'ACTUAL',
    subscriberEmailAddresses: [config.require('notificationEmail')], // no default: a budget that mails nobody is useless
  })),
});
