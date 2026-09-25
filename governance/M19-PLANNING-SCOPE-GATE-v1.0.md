# PAI-FORGE — M19 PLANNING / SCOPE GATE v1.0

**Status:** PROPOSED — PLANNING GATE / NO IMPLEMENTATION AUTHORIZED
**Date:** 2026-09-25
**Repository:** `kelebek10/ai-studio-os`
**Branch:** `phase-1-3-foundation`
**Baseline:** `dfc0fcc5f66c17b533f4be6bec653220eae1ba6e`
**Coordinator:** GPT-5.6 Luna
**Predecessor:** M18.6 CLOSED / VERIFIED

## 1. Amaç

M18–M18.6 ile doğrulanan üretim runtime, güvenlik, Human Gate, delegation, evidence, rollback ve authority sınırlarının üzerine kalıcı bir **durable task-control / mission orchestration layer** kurmak.

Amaç; mevcut kontrollü görev sözleşmesini yalnızca çalışan pipeline seviyesinde bırakmayıp, görev atama, acknowledgement, durum ilerlemesi, event/provenance ve sonuç handoff süreçlerini deterministik ve yeniden başlatılabilir hale getirmektir.

M19 yeni AI yetkisi vermeyecek. M18'de doğrulanan authority modelini kullanacaktır.

## 2. Kapsam

M19 kapsamı:

1. Canonical Task Control Plane
2. Durable task/event lineage
3. Deterministic assignment + acknowledgement
4. Idempotent task progression
5. Result submission → GPT verification → terminal state akışı
6. Retry/recovery için kontrollü state handling
7. Human Gate entegrasyonunun task-control seviyesinde korunması
8. Audit/evidence provenance'in görev yaşam döngüsüyle bağlanması
9. Operational status'un mobil/Telegram yüzeylerine güvenli şekilde sunulabilmesi için API contract hazırlığı

M19 kapsamı dışı:

- Yeni Core Agent oluşturulması
- AI/provider'a approval authority verilmesi
- Human approval mekanizmasının değiştirilmesi
- M14 sınırının değiştirilmesi
- M17'nin yeniden açılması
- M18/M18.5/M18.6'nın yeniden tasarlanması
- Production DB migration'ı ilk görevde yapmak
- Serbest AI-to-AI communication
- Multi-agent swarm/autonomous self-provisioning
- Vision/3D/landscape intelligence ürün özellikleri

## 3. M18'den devralınan teknik altyapı

Verified baseline:

- M18 production gateway: `m18-runtime-gateway`
- Qwen3 provider: `qwen3:1.7b`
- Persistent Agent Registry
- PostgreSQL + PgBouncer
- bounded Core/Specialist hierarchy
- Human-only approval boundary
- provider authority contracts
- RLS-enforced registry boundary
- ModelAdapter
- Orchestrator
- OrchestratorPipeline
- Reviewer / Evidence / Security / Human Gate
- production rollback/restore evidence
- M17 non-regression baseline
- M18.6 final audit: CLOSED / VERIFIED

Current task contract baseline:

`governance/TASK-CONTRACT-v1.0.md`

The contract explicitly identifies durable dispatch, acknowledgement, event persistence and automatic progression as future implementation work.

## 4. Yeni modüller

### M19.1 — Task Control Plane Contract
Canonical task state machine, commands, events, idempotency and terminal-state rules.

### M19.2 — Durable Task/Event Ledger
Persistent task lineage and immutable event history.

### M19.3 — Deterministic Dispatcher
Assignment based on registered agent/provider/scope/authority.

### M19.4 — Acknowledgement + Lease/Recovery
Agent acknowledgement, timeout/recovery semantics and duplicate-execution protection.

### M19.5 — Result Handoff Gate
RESULT_SUBMITTED → GPT_REVIEW → VERIFIED / REWORK_REQUIRED / BLOCKED / HUMAN_ACTION_REQUIRED / CLOSED.

### M19.6 — Operational Status API Contract
Read-only status exposure for future mobile/Telegram operational surfaces.

Implementation order remains subject to M19.1 design evidence.

## 5. AI orkestrasyon görevleri

AI orchestration remains task-bound.

M19 orchestration responsibilities:

- deterministic task classification;
- deterministic routing;
- registered-agent capability matching;
- scope validation;
- authority validation;
- acknowledgement tracking;
- result handoff;
- evidence binding;
- conflict manager integration;
- Human Gate escalation;
- fail-closed recovery.

Rules retained:

- no free AI-to-AI conversation;
- maximum three conflict rounds;
- no AI self-approval;
- no AI-created human authority;
- no provider registry write authority;
- no silent scope expansion.

## 6. Veri / DB etkileri

Planning assumption:

M19 will likely require durable task/event persistence, but **no production schema mutation is authorized by this planning gate**.

Candidate logical entities:

- task
- task_event
- task_assignment
- task_attempt
- task_handoff
- task_evidence_reference

Required properties:

- stable task identity;
- correlation/lineage;
- source commit;
- actor/agent;
- state transition;
- timestamp;
- idempotency key;
- evidence reference;
- failure/block reason.

Any schema change must receive a separate implementation gate and migration evidence.

## 7. Mobil ürün etkisi

M19 does not build the end-user mobile application yet.

It establishes the backend contract required for a mobile-first operational experience:

- task status;
- project/job status;
- pending human action;
- blocked reason;
- execution progress;
- evidence/result availability;
- safe notifications.

Mobile clients remain read-oriented against the operational control plane until authorization rules are separately defined.

## 8. Riskler

### R1 — State duplication
Multiple components may maintain conflicting task state.

**Control:** one canonical task record + immutable event lineage.

### R2 — Duplicate execution
Retry may execute the same mission twice.

**Control:** idempotency key + attempt identity + deterministic state transitions.

### R3 — Authority escalation
Task metadata could accidentally grant authority.

**Control:** task contract cannot exceed registry/permission/governance authority.

### R4 — Persistence becoming a new attack surface
Durable events may be forged or mutated.

**Control:** restricted DB roles, append-only semantics where appropriate, provenance and integrity verification.

### R5 — Runtime coupling
M19 could destabilize the verified M18 gateway.

**Control:** modular implementation, isolated tests, no modification of protected M18 baseline without a controlled gate.

### R6 — Premature complexity
M19 could become a multi-agent platform before the durable control plane is proven.

**Control:** deterministic-first; no swarm, no autonomous provisioning, no unnecessary infrastructure.

## 9. Acceptance criteria

M19 may only be closed when fresh runtime evidence demonstrates:

1. A task can be created with canonical identity.
2. Assignment is deterministic and scope/authority checked.
3. Agent acknowledgement is durable.
4. State transitions are deterministic and persisted.
5. Duplicate delivery does not create uncontrolled duplicate execution.
6. Restart/recovery preserves task lineage.
7. Result handoff cannot bypass GPT verification.
8. Evidence remains bound to the correct task/correlation lineage.
9. Human Gate remains human-controlled.
10. Provider output cannot assert `APPROVED`.
11. Conflict round 4 remains fail-closed.
12. Unauthorized task/control fields remain blocked.
13. M17 regression remains clean.
14. Existing M18 production identity and security boundary remain intact.
15. All PASS claims have real execution evidence.

## 10. M19 kapanış koşulları

M19 is CLOSED only when:

- all scoped M19 components have explicit acceptance evidence;
- no unresolved P0/P1 authority or integrity defect remains;
- production mutation, if any, has a separately approved gate and rollback evidence;
- M17 remains CLOSED and unmodified;
- M18/M18.5/M18.6 remain CLOSED unless a documented regression trigger exists;
- governance, runtime, tests and evidence are reconciled;
- final closeout document is committed;
- next milestone has not been started implicitly.

## Planning Gate Decision

**M19 is defined as a controlled planning scope only.**

No implementation begins until M19.1 is converted from planning to an approved implementation task.

### First controlled technical task

**M19.1 — Task Control Plane Contract & Event Model**

Deliver:

- canonical task state machine;
- command/event vocabulary;
- transition matrix;
- idempotency model;
- attempt/retry semantics;
- event provenance model;
- failure/blocked semantics;
- Human Gate interaction;
- acceptance-test matrix.

Constraint:

**Design first. No production DB migration and no M18 runtime mutation in M19.1.**

## Change control

Any material scope expansion requires a new version of this document and explicit human approval before implementation.
