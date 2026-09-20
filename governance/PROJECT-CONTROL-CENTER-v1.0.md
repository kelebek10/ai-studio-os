# PAI-FORGE — PROJECT CONTROL CENTER

Document ID: PCC-001
Version: 1.0
Status: CONTROLLED DESIGN BASELINE
Branch: phase-1-3-foundation
Owner: Human Project Owner
Parent: AI-OPS-001
Constitutional Control: PAI-FORGE-001A

## 1. Purpose

Provide a single, short-form operational status model so the Human Project Owner can determine the current project state without reading implementation details.

The Control Center is an observability layer. It is not an authority layer and cannot approve, unblock, or authorize protected actions.

## 2. Canonical Statuses

- `WORKING` — controlled work is actively executing.
- `WAITING` — work is intentionally paused pending an external event or scheduled continuation.
- `REVIEW_REQUIRED` — evidence/result exists and independent review is required before progression.
- `HUMAN_ACTION_REQUIRED` — explicit Human Project Owner action is required.
- `BLOCKED` — a control, evidence, permission, dependency, security, or governance condition prevents progression.
- `STOPPED` — work was deliberately stopped by a control rule or authorized operator.
- `COMPLETED` — defined task acceptance criteria are satisfied and evidence is recorded.
- `UNVERIFIED` — claimed completion cannot yet be supported by sufficient execution evidence.

No status may be upgraded merely by changing this document.

## 3. Minimum Status Record

Every active controlled task shall expose, at minimum:

- task_id;
- task title;
- current status;
- responsible agent/model;
- current stage;
- branch;
- source commit;
- started_at / last_updated_at;
- blocking condition, if any;
- next action;
- evidence reference;
- human action required: yes/no.

## 4. Status Transition Rule

Status transitions follow:

**CONTROL → VERIFY → DECIDE → EXECUTE → RE-CONTROL**

Only a validated task event may change operational status.

Natural-language messages, Telegram messages, AI consensus, or manual edits without evidence are not authoritative transition events.

## 5. Human View

The Human Project Owner view shall prioritize, in this order:

1. current status;
2. whether work is active;
3. whether the project is blocked;
4. whether human action is required;
5. current task/stage;
6. responsible agent;
7. last verified event;
8. next action.

Detailed evidence remains in GitHub/evidence records and is not duplicated into the short status view unless required for traceability.

## 6. Notification Boundary

Future notification adapters, including Telegram, may publish status changes from this Control Center.

Notifications are informational only.

Telegram or another notification channel shall never be an approval authority, security control, provenance source, or Core mutation channel.

## 7. Stale-State Rule

A status is not considered current solely because the Control Center file contains it.

A future runtime implementation shall verify freshness against task events/evidence and shall expose `UNVERIFIED` or `BLOCKED` when freshness cannot be established.

## 8. Failure and Safety

If the status source, task identity, event lineage, evidence, or authority context is missing or contradictory, the visible state shall fail closed to `UNVERIFIED` or `BLOCKED` as applicable.

No status display may hide a blocking condition to make the project appear active or complete.

## 9. Integration Boundary

This v1.0 document defines the status contract only.

It does not yet authorize:

- automatic agent activation;
- privileged tool access;
- human authorization;
- production mutation;
- Telegram command execution;
- autonomous status rewriting.

Runtime implementation requires separate verified Task Contract, Agent Registry, Permission Model, Tool Access Policy, event/evidence schema, and notification adapter controls.

## 10. Acceptance Criteria

PCC-01: One active task can be represented with the minimum status record.

PCC-02: WORKING, BLOCKED, HUMAN_ACTION_REQUIRED and COMPLETED are distinguishable without reading detailed evidence.

PCC-03: A notification channel cannot change authority or task status by itself.

PCC-04: Missing or stale control context cannot produce a falsely healthy status.

PCC-05: Status remains traceable to task/evidence identity.

PCC-06: Control Center remains an observability layer and cannot become a hidden authority layer.

## 11. Current State

This is a controlled design baseline. Runtime implementation and Telegram integration remain pending independent verification.
