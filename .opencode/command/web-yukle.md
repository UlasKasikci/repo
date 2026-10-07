---
description: App-Fabrika P5 — QA PASS ise Yukleme/ üret, sha256 manifestli teslim raporunu sun ($ARGUMENTS = proje dizini, boşsa .)
---

Proje dizini: `$ARGUMENTS` (boşsa `.`).

1. Ön kapı: `bash scripts/web/state.sh status $ARGUMENTS` → faz **P5** ve
   `qa-report.json` → `"result": "PASS"` olmalı. Değilse `/web-denetle` çalıştır ve dur.
2. `bash scripts/web/package-yukleme.sh $ARGUMENTS`
3. `packaging-report.json` oku: files_count, bytes_total, sql_output, skipped, notes,
   manifest sha256.
4. Doğrula: `Yukleme/` §14 ağacı birebir; `node_modules`, `.env`, `.git`, `*_test.php`,
   `.scss`/`.ts` sızmamış; `Yukleme/SQL/veritabani.sql` UTF-8 + FK + seed içeriyor.
5. Teslim raporu sun: dosya sayısı, byte, SQL durumu, minify notları, FTP hedefi `Yukleme/`.
6. (Opsiyonel, P5 sonrası raporlayıcı) Canlı doğrulama: `LIGHTHOUSE_URL` tanımlıysa
   `bash scripts/web/lighthouse-verify.sh $ARGUMENTS` → `.factory/lighthouse-report.json`
   (PASS/WARN/SKIPPED; v1 bloklayıcı değil, eşik altı WARN'de exit 0; `--strict` ile exit 1;
   geçici sunucu için `--serve`). State graph'a girmez, `Yukleme/`'ye (.factory denylist)
   girmez; URL yoksa SKIPPED exit 0 ile biter.

`Yukleme/` asla commit edilmez; rapor proje kökünde kalır, ağaca ek dosya konmaz.
