# FINDINGS — Tur 2-14 · RUN-REPORT-2 §6 Fix'leri (B-1 + B-2) → v1.0-rc4

**Tarih:** 2026-10-11 · **Sonuç:** 2/2 fix tamam · self-test **49/49 PASS** · CI yeşil · tag `v1.0-rc4`
**Kaynak:** RUN-REPORT-2 §6 (Tur 2-13 saha bulguları) · **K6:** kontrol sayısı DEĞİŞMEDİ (`set_check` 7 → 7)

## B-1 — kvkk regex `IF NOT EXISTS` false negative (SEV-3)

- **Önce:** `qa-gate.sh` kvkk kanalı iki tabloyu
  `CREATE TABLE[[:space:]]+`?user_consents`` ile arıyordu —
  `CREATE TABLE IF NOT EXISTS user_consents` (elle yazılmış dump biçimi)
  **eşleşmiyordu** → hatalı `kvkk: ... tablosu yok` FAIL. Tur 2-13'te yalnızca
  `sql-dump.sh` düz biçim ürettiği için kurtarılmıştı; manel yazım = kör nokta.
- **Fix:** opsiyonel grup — `CREATE TABLE([[:space:]]+IF NOT EXISTS)?[[:space:]]+`?tablo``
  (düz, backtick'li, IF NOT EXISTS, çift boşluklu biçimler hepsi eşleşir).
- **Kanıt (senaryo 47):** üç uç durum, hepsi `qa-gate --record` sonrası
  `qa-report.json → checks.kvkk` üzerinden:
  - düz `CREATE TABLE \`user_consents\`` → **PASS** (regresyon — eski biçim
    yeni regex'le de kırılmamalı),
  - `CREATE TABLE IF NOT EXISTS user_consents` → **PASS** (fix),
  - tablo hiç yok → **FAIL** (duyarlılık — test gerçekten fail edebilmeli).
  - Not: tablolar `SQL/migrations/schema/999_kvkk.sql` + `sql-dump.sh` ile
    üretildi (drift kapısı da böylece kandırılmadı — dump ham birleştirir,
    `IF NOT EXISTS` metni korunur, 1 eşleşme doğrulandı).
- **Kapsam dışı (gözlem):** `USERS_RE`/`CATALOG_RE`/`CART_RE` (qa-gate.sh:127-129)
  aynı düz kalıbı paylaşıyor; pratikte `sql-dump.sh` çıktısı düz olduğu için
  kör nokta oluşmuyor — elle yazılmış dump'larda da vurabilir (sonraki tur adayı).

## B-2 — hybrid modda P2 LLM çağrısı garantisi (SEV-2)

- **Önce:** Hybrid çıkış (`P2_HUMAN_ASSIST=true && ! scaffold_ok` → template +
  exit 3) yalnızca `P2)` case'indeki **tek çağrı noktası öncesindeydi**; `run_agent`
  içinde hiçbir koruma yoktu ve `--auto` + hybrid kombinasyonu **hiç test
  edilmemişti** (senaryo 42/45 `--auto` OLMADAN koşuluyordu). Tur 2-13 sahasında
  tam da `--auto` yolunda istemsiz P2 auto gözlendi (275 s, 0 write israfı).
- **Fix:** `run_agent()` başındaki invariant guard'ı — `phase == "P2" &&
  P2_HUMAN_ASSIST=true` → ajan çağrısız, model çözümlemesiz, **LLM'e gitmeden
  exit 3** (+ net mesaj). P2 case'indeki şablon-kopya dalı yerinde durur (UX);
  guard, çağrı noktası refactorda kaysa bile "HİÇ çağrılmaz" sözünü kilitler.
- **Kanıt (senaryo 48):** stub `opencode` (çağrıları log'lar, exit 1) + iki koşu:
  1. **duyarlılık (hybrid YOK, `--auto`):** `--agent web-core-engineer` **1×**
     çağrıldı + `metrics.jsonl`'de **phase=P2 satırı var** → test, hatayı
     gerçekten yakalayabilir,
  2. **hybrid (`P2_HUMAN_ASSIST=true --auto`):** log **0 satır**, `metrics.jsonl`
     **yok** (LLM satırı üretilmedi), stdout'ta `opencode agent` satırı yok,
     **exit 3** + `HYBRID` mesajı.
- **Kapsam notu:** P4 (QA revizyonu) `web-core-engineer`'ı `phase=P4` ile çağırır —
  task tanımı "P2" ile sınırlı; P4 hybrid'de otomatik revizyon çağrısı açık soru
  olarak kaldı (revizyon QA geçene kadar insanın işi mi — sonraki tur kararı).

## Doğrulama

- `bash -n` 3 dosya OK (self-test/qa-gate/orchestrate).
- **self-test 49/49 PASS** (47 → 49: senaryo 47=B-1, 48=B-2; K5 B.3 badge
  tutarlılığı README `49%2F49` ile yeşil).
- qa-gate diff'i **yalnız regex** (kontrol sayısı/kapı davranışı değişmedi — K6).
- README: Release `v1.0-rc4` satırı + Production Readiness "kalan" cümlesi
  güncellendi; MASTER-PROMPT badge 49/49.
- CI: yeşil (bu dosyanın commit'i dahil) · tag: `v1.0-rc4` (rc3 üzerine fix).

## Sonraki tur (kısa özet)

Gerçek proje: kullanıcı freelance işlerinden birini seçer → `/kur` → P1 →
hybrid P2 (manel iskelet) → P3 → P5 → teslim. Ölçüm: süre, token, manel
müdahale sayısı — v1.0-rc4 zeminiyle.
