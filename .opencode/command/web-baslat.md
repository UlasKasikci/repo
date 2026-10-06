---
description: App-Fabrika P1 — domain analizi başlat, state'i P1'e al, proaktif eksik modül denetimini çalıştır ($ARGUMENTS = proje dizini, boşsa .)
---

Proje dizini: `$ARGUMENTS` (boşsa `.`).

1. `bash scripts/web/state.sh status $ARGUMENTS || bash scripts/web/state.sh start $ARGUMENTS`
2. `docs/WEB-EDITION.md` §3 + `.cursor/rules/25-web-domain-architect.mdc` listesini uygula:
   `users` → `role_id`/`permissions`; katalog → sepet/sipariş/teklif; ödeme/bildirim/SEO/KVKK
   eksiklerini öner ve enjekte et.
3. Proje dosyaları varsa deterministik kanıt: `bash scripts/web/qa-gate.sh $ARGUMENTS` +
   `qa-report.json` oku.
4. P1 raporunu **zorunlu artefakt** olarak yaz: `$ARGUMENTS/.factory/domain-report.json`
   (UTF-8 JSON; şema: `.factory/contracts/p1-domain-report.schema.json` — `module_matrix`
   her modül için `present|missing|injected|proposed` + evidence): varlıklar, roller,
   enjekte modüller, onay bekleyen istisnalar, edge case'ler, security context, SQL taslağı.
   `bash scripts/web/orchestrate.sh $ARGUMENTS` bu artefaktı doğrular (yoksa exit 3 bekleme,
   geçersizse exit 1).
5. Kullanıcı onaylayınca: `bash scripts/web/state.sh advance $ARGUMENTS` (requirements-frozen
   → P2) veya tüm zincir için `bash scripts/web/orchestrate.sh $ARGUMENTS`. Kullanıcı
   onaysız P2'ye geçme.
