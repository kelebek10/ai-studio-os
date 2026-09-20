# PEYZAJ AI / PAI-FORGE — Project Handoff

**Document:** PROJECT-HANDOFF.md  
**Version:** 1.0  
**Status:** APPROVED  
**Owner:** Human Project Owner

## 1. Project Purpose

PEYZAJ AI / PAI-FORGE; Balıkesir ve Kuzey Ege odaklı, kanıta dayalı, deterministic-first bir **Landscape Intelligence Engine + AI Design Layer** geliştirmektir.

Temel prensip:

**Structured-First → Semantic-Second → LLM-Last**

## 2. Current Phase

**Phase 1–3 Foundation**

Governance, veri sınırları, Identity Model ve Core mimari temelleri oluşturulmaktadır.

Production implementation ve database migration henüz başlatılmamıştır.

## 3. Finalized Decisions

- Core model-agnostic olacaktır.
- AI modelleri Core üzerinde bağımsız karar veremez.
- Human Project Owner final authority'dir.
- Google Sheets yalnızca Candidate Research Interface'tir.
- Unverified data doğrudan Core'a giremez.
- RAW veri immutable tutulur.
- n8n Core'a yazamaz.
- AI Proposal ≠ Approved Core State.
- Entity ID scientific identity'nin tekil ve kalıcı kimliğidir.
- Merge ≠ Delete.
- Split sonrası otomatik knowledge migration yapılmaz.
- Evidence ≠ Knowledge ≠ Decision.
- Evidence invalidation knowledge'ı otomatik invalidate etmez.
- Tenant ID ≠ Scientific Identity.
- `expected_version`, `event_sequence` ve `idempotency_key` birbirinden ayrıdır.
- Kesinleşen karar önce GitHub'a kaydedilir, sonra implementation yapılır.
- `main` branch'e doğrudan yazılmaz.

## 4. Last Completed Work

Identity Model v1.2 Constraint Matrix **APPROVED** olarak GitHub'a kaydedildi.

Decision Recording Standard da GitHub'a kaydedildi.

Aktif branch:

`phase-1-3-foundation`

## 5. Next Step

**PostgreSQL Schema Blueprint**

Constraint Matrix'teki kurallar PostgreSQL tablo, constraint, index, role ve permission tasarımına dönüştürülecek.

Schema review tamamlanmadan production migration yapılmayacaktır.

## 6. Critical Prohibitions

- `main` branch'e izinsiz değişiklik yok.
- APPROVED olmayan karar implementation'a dönüşmez.
- AI doğrudan authoritative Core state değiştiremez.
- n8n Core write credential alamaz.
- RAW kayıtları UPDATE/DELETE/TRUNCATE edilemez.
- Entity ID silinemez.
- Evidence invalidation otomatik knowledge invalidation yapamaz.
- Production DB migration schema review olmadan çalıştırılamaz.
- Gelecekte gerekli olabilecek sistemler bugünden gereksiz yere inşa edilmez.

## 7. Required Reading

Yeni çalışma oturumunda önce:

1. `governance/CURRENT-STATE.md`
2. `governance/DECISION-RECORDING-STANDARD.md`
3. `governance/IDENTITY-MODEL-v1.2-CONSTRAINT-MATRIX.md`
4. `governance/PROJECT-HANDOFF.md`
5. İlgili ADR ve governance kayıtları
6. Son `phase-1-3-foundation` commitleri

## 8. Recovery Rule

Yeni sohbet veya bağlam kaybında:

**GitHub → governance → CURRENT-STATE → son karar → son commit → sonraki adım**

izlenir.

Sohbet hafızası ile GitHub kaydı çelişirse, **onaylanmış GitHub governance kaydı esas alınır.**
