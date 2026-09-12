# PEYZAJ AI / PAI-FORGE — Decision Recording Standard

**Document:** DECISION-RECORDING-STANDARD.md  
**Version:** 1.0  
**Status:** APPROVED  
**Scope:** Governance / Decision Recording  

## 1. Purpose

Kesinleşen proje kararlarının GitHub üzerinde standart, izlenebilir ve geri dönülebilir şekilde kayıt altına alınmasını sağlar.

## 2. Mandatory File Structure

Karar kayıtları `governance/` altında tutulur.

- Mimari karar → `ADR-<KONU>.md`
- Standart/kontrat → `<KONU>-STANDARD.md`
- Kısıt matrisi → `<KONU>-CONSTRAINT-MATRIX.md`
- Güncel proje durumu → `CURRENT-STATE.md`

Her kayıt aşağıdaki zorunlu alanları içermelidir:

- `Document`
- `Version`
- `Status`
- `Date`
- `Owner`
- `Decision`
- `Rationale`
- `Impact`
- `Next Step`

## 3. Branch Policy

Tüm governance karar kayıtları:

`phase-1-3-foundation`

branch'inde oluşturulur.

`main` branch'ine doğrudan yazılmaz.

## 4. Commit Message Standard

Format:

`governance: <kısa karar açıklaması>`

Her önemli ve bağımsız karar anlamlı bir commit ile kaydedilir.

## 5. Status Values

Yalnızca aşağıdaki durum değerleri kullanılabilir:

- `PROPOSED` — Önerildi, henüz onaylanmadı.
- `APPROVED` — İnsan Proje Sahibi tarafından onaylandı.
- `IMPLEMENTED` — Onaylanan karar uygulandı ve doğrulandı.
- `SUPERSEDED` — Daha yeni bir kararla değiştirildi.
- `DEPRECATED` — Kullanımdan kaldırıldı.

## 6. Core Rule

**Kesinleşmeyen karar GitHub'a nihai karar olarak yazılmaz.**

**Kesinleşen karar önce GitHub'da kayıt altına alınır, ardından implementation aşamasına geçilir.**

Production, schema veya geri dönüşü zor değişiklikler yalnızca `APPROVED` durumundan sonra uygulanabilir.

**Human Project Owner final authority'dir.**
