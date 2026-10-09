---
name: kvkk-compliance
description: KVKK/GDPR uyumluluk modülü — aydınlatma metinleri, çerez rıza banner'ı, user_consents/anonymization_log şeması; intent.compliance=kvkk|gdpr olan projelerde P2 öncesi kullan.
---

# KVKK/GDPR Compliance (iskelet — v2'de doldurulur)

**Durum:** iskelet · **Bağlantı:** `docs/WEB-EDITION.md` §3 (compliance koşullu modül #9) ·
`qa-gate.sh` → `kvkk` kanalı.

## Ne zaman çağrılır

`project-intent.json` → `compliance ∈ {kvkk, gdpr}` ise P2 (kod üretimi) öncesi —
domain-report yazılırken bileşen listesi dondurulur.

## Modül adımları (v2 planı — içerik doldurulacak)

1. **Görünüm/FAQ metinleri:** `views/legal/aydinlatma.php`, `views/legal/gizlilik.php`,
   `views/legal/cerez.php` — gerçek yasal metin (şablon değil).
2. **Çerez rızası:** `views/partials/cookie-consent.php` (açık rıza banner'ı) +
   `assets/js/cookie-consent.js` (kaydetme/red, `HttpOnly` olmayan tercih çerezi).
3. **DB:** `SQL/migrations/schema/*_kvkk.sql` → `user_consents` + `anonymization_log`
   (boş şema, seed değil) → `bash scripts/web/sql-dump.sh` ile dump yeniden üret.
4. **domain-report:** `file_manifest` içine legal view'lar + partial + JS eklenir
   (manifest-onaylı içerik okuma — Q1 tamamlama modeli).

## qa-gate beklentileri (`kvkk` kanalı)

- 3 legal view + cookie-consent partial + cookie-consent.js → dosya varlığı zorunlu.
- `SQL/veritabani.sql` → `CREATE TABLE user_consents` + `CREATE TABLE anonymization_log`.
- Eksik → FAIL; `compliance=none`/alan yok → kanal SKIPPED (PASS'i etkilemez).

## Yasak

- `compliance=kvkk|gdpr` iken tek bir bileşenin "yeterli" sayılması (kanal bütünseldir).
- Yasal metni placeholder/lorem ile doldurmak (K5: belge kanıttan türesin).
