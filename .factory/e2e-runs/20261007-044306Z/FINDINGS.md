# E2E-2 SAHA TATBİKATI — `20261007-044306Z` (B1 fix sonrası, karşılaştırmalı)

**Sonuç: `DRIVER_DONE rc=0 attempts=1`, `state=DONE`, `retry=0`, tek WD, kill YOK**
04:43:07Z → 07:00:20Z (2s17dk; P1 24.6dk + P2 112.5dk + QA 4sn + P5 6sn).
Senaryo run1 ile **birebir aynı** (`project-intent.json` sha256 `2e481696…007` eşit).
Baz: commit `d88cd10` (B1 `mode: primary` + B4 kill-safe metrics).

## 1. B1 kanıtı — çok-ajanlı ayrım GERÇEK

- `metrics.jsonl` = **2 satır, 2 farklı ajan, 2 farklı session**:
  - `P1 web-domain-architect` rc0 · 1474s · 623.8k token · 14 step · `ses_eeb53db…`
  - `P2 web-core-engineer`   rc0 · 6748s · **4194.6k token** · 55 step · `ses_eeb3d5c…`
- Log'da **`falling back to default agent` uyarısı: 0** (run1'de P1'de vardı).
- Bağımsız çıktı kanıtı: P1 modül adlandırmaları run1'den farklı
  (`kvkk-compliance`, `contact-messaging`, `notification: proposed`).
- **B4 kanıtı:** P2 satırı mevcut (run1'de watchdog kill'ı ile kaybolmuştu).

## 2. Kabul kriterleri (run2)

| Kriter | Sonuç |
|---|---|
| qa-gate | **PASS 0/0 — 13/13 kanal** (kvkk, sql_dump, phpstan, phpunit, eslint, static_coverage, domain_report, …) |
| `Yukleme/` | ✓ §14, sızıntı yok (`.opencode/.cursor/scripts` skipped) |
| smoke | **PASS** 0/0 + `.htaccess` notu |
| MANIFEST | yok (ilk paket — beklenen) |
| state | `start→P2→P3→qa-pass(4sn)→DONE(6sn)` |

## 3. P1→P2 DRIFT — run1 farkı: AYRI AJANLARA RAĞMEN ÖRTÜŞME

- entities ↔ SQL: **5/5** (`roles, users, messages, user_consents, anonymization_log`);
  eksik/fazla **0**.
- Bu, run1'deki "tek ajan + keşif" hipotezini **zayıflatıyor**: örtüşme, P2 prompt'undaki
  **garantili kısıtlardan** geliyor (KVKK bloğu tablo isimlerini birebir veriyor +
  intent notes domaini tarif ediyor + spec RBAC zorunlu). `domain-report.json`'un
  açık referansı hâlâ prompt'ta **yok** (savunmacı iyileştirme, kanıt: drift görmedi).
- **Contamination testi:** run2 kaynakları vs run1 snapshot — **27 dosyanın 0'ı birebir
  aynı**, SQL dump hash'leri farklı → kopya yok, bağımsız üretim.

## 4. YENİ BULGU (run1 kanıtından): bootstrap `.factory/e2e-runs` prune eksik

Run2 bootstrap'ı, commit'li run1 artefaktlarını (`project-snapshot/` 36 PHP dahil)
**yeni projeye kopyaladı** — P2 keşifte bunları gördü (kopya olmadı, hash testi yukarıda).
QA'ya zarar vermedi (PHP envanteri `.factory` prune'lar). Düzeltme adayı:
`bootstrap-project.sh` `PRUNE_REL_DIRS` → `.factory/e2e-runs`.

## 5. B2 — B1 fix'ten sonra KALDI

- write `SchemaError` gözlemi: P1=1, P2=4 (**toplam 5**, run1=5 ile aynı seviye).
- Model default/primary farkı olmadan da `content=obje` üretiyor → **prompt fix**
  (P1/P2/P4: "write tool `content` string olmalı") gerekiyor; opencode sürümü değil.

## 6. Metrik karşılaştırması (strict zemini, n=2)

| | run1 (subagent fallback) | run2 (primary) |
|---|---|---|
| P1 latency / token | 1548s / 412.5k | 1474s / 623.8k |
| P2 latency / token | ~7200s / ≥3.1M (kill) | 6748s / 4194.6k |
| toplam duvar saati | ~2.5s (kesintili) | 2s17dk (temiz) |
| QA → DONE | 12sn | 10sn |
| kesinti/watchdog kill | 1 (WD2 yarışı) | 0 |
| write SchemaError | 5 | 5 |

Öneri eşiği (n=2, temiz koşu): `E2E_TIMEOUT_SEC=10800` yeterli; `E2E_MAX_TOKENS` P2 tek başına
4.2M'ye çıkıyor → **9M tavanı kalibre** (ör. P2 başına 6M, toplam 8M).

## 7. Sıra tablosu statüsü

1. B1 fix ✓ · 2. B4 trap ✓ · 3. İkinci E2E ✓ (bu belge) ·
4. P1→P2 kontrat: **drift görülmedi** — açık referans opsiyonel (karar: kullanıcı) ·
5. B2 tekrar: **KALDI** → prompt fix gerekli ·
6. P4 hata-enjeksiyonu: bekliyor · 7. `--strict` eşiği: n=2 zemin hazır, karar bekliyor.
