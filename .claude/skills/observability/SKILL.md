---
name: observability
description: >
  Rules for logs, metrics, alarms, alerts and notifications of a service. Use whenever you write or change
  an alarm, a log line at error level, a metric, a monitoring rule, a notification mail or a sweep/cron
  job that flags "stuck", "overdue" or "failed" items. Also use when the user shows an alert that is
  unclear, noisy or not actionable, or asks how a failure should be reported. Triggers on: "alarm",
  "alert", "monitoring", "logging", "metrics", "on-call", "notification", "overdue", "stuck".
---

# Observability

An alert is a message to a tired person. The person must decide in one read: how bad, how soon, what to do.

## The alert test

Read the alert text alone, without the code. Answer 5 questions. If one answer is missing, the alert is not done.

1. **What broke?** A named fault, not a symptom. "Document overdue" fails: it does not say if the send, the delete or a payment failed.
2. **How severe?** What is the harm: money lost, customer without service, data kept too long, no harm yet.
3. **How urgent?** Act now, today, or next week. Say what gets worse with time.
4. **How many?** Count of orders, users, files or requests that the fault touches. Add the age of the oldest.
5. **What next?** The first action, or the runbook name. "Refund order X" is an action. "Investigate" is not.

Put the IDs in the alert, so the person can find the object without a search. Put no personal data in it.

## A stuck state is a process bug

If an item can stay "overdue", "stuck" or "pending" with no owner, the process is broken, not only the alert.

- Every state must end in a terminal state, or have a timeout that moves it to one. Example: a letter that the carrier does not confirm in time fails and the payer gets a refund.
- If a person must decide, the state is `needs_review`. The alert names the item, and the item stays visible until the person acts.
- An "overdue" alarm is the last backstop for a hole in the process. Each time it fires, ask first: which transition was missing? Then add it. Do not only make the text better.
- A sweep that flags a state without a name for the cause is a smell. Give each cause its own alarm.

## Coverage: who hears about what

Sort every failure into one of 3 classes. A failure with no class is a gap.

| Class | Rule | Example |
| --- | --- | --- |
| Heals itself | The system retries or recovers, and the end state is correct. No human action. Count it in a metric; alert only if the rate or the age passes a limit. | A retry of a read succeeds. A late webhook marks the order paid. |
| Needs a person | A human must decide or act. An alarm names the item and the first action. | A refund. A letter in an unknown state. A mailbox over its limit. |
| Unknown | No code path expected it. Always an alarm. | Every unhandled exception, rejected promise, crash and timeout. |

Rules for the sort:

- **Every unhandled exception notifies the operator.** Catch at the top of each entry point (request handler, job, scheduled run, queue consumer) and log at error level. A `catch` that swallows a fault without a log and a class is a bug.
- **A timeout, a crash or an out-of-memory stop is an unhandled exception.** The code cannot log it, so a platform alarm (error count, throttles, dead-letter queue, missing run) must cover it.
- **Fail fast, then classify.** A fault in a money path, a data-loss path or a security check never continues silently. It stops, and it raises an alarm.
- **Customer impact decides the class.** If a customer pays for a result and does not get it, a person must know, even when the cause looks small.
- **Heals itself needs proof.** Show the end state in a metric or in a test. Else treat it as "needs a person".
- **A dependency that is down** (payment, carrier, mail, database) raises one alarm for the dependency, not one per request.
- **Cover the absence of events.** A job that does not run, a webhook that does not arrive and a queue that does not empty need a check on time, not on an error.
- **Security and limit events** (blocked abuse, cost cap reached, quota at 80 %) notify at the first crossing, then in a digest.

## Logs

- One line, one event, structured (JSON). Keys: `alarm` or `event`, IDs, status, a count or an age, `error` text.
- Log IDs, never personal data (names, addresses, email, document content).
- Log at the boundary where the fault is known. Do not log the same fault at each layer.
- Log level means action. `error` means a person must act. A fault that the system handles alone is `warn` or `info`.
- Keep log retention equal to what the privacy notice promises.

## Metrics

- Count what you alert on: handled, failed, skipped. A metric of the form "handled by X" lets a second alarm find what X missed.
- Measure rates and ages (oldest item in each state), not only totals.
- Label with a small fixed set of values. An ID is never a label.

## Alarms and notifications

- An alarm name is a type. The first line of a type goes out at once. Further lines of the same type are counted and sent in one digest with the count and the times.
- Keep a backstop: an independent alarm that compares the log with the handled count. Never remove it because the main path "works".
- Page for what needs a person within hours. Send everything else to a digest or a dashboard. Noise trains people to ignore the mail.
- A silent failure is the worst case. Check that a missing job run, an empty queue that should not be empty, and a failed alarm sender all raise something.
- Remove personal data before a notification leaves the account, and cut long lines.

## Check before you finish

- Trigger the alarm once in a test and read the resulting text. Check it against the alert test.
- Check that the alarm fires once per fault and not once per retry or per item.
- Write the alarm name, its cause and its first action in the docs of the repo (the file that owns operations).
