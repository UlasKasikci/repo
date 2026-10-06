# /web-faz — State Graph Durumu

Aktif fazı ve kanıt dosyalarını okur — salt okunur, durumu değiştirmez.

## Komut

```bash
bash scripts/web/state.sh status
```

## Kanıt taraması

```bash
grep '"result"' qa-report.json 2>/dev/null || echo "qa-report yok"
grep '"result"' packaging-report.json 2>/dev/null || echo "packaging-report yok"
ls debug_report.json 2>/dev/null && echo "debug_report VAR (HALT/FAIL kanıtı)"
```

## Çıktı tablosu

| Alan | Değer |
|------|-------|
| Faz | P1–P5 / HALT |
| Retry | n / max_retries: 3 (4. fail HALT) |
| QA | PASS / FAIL / yok |
| Paketleme | PASS / yok |
| Sonraki adım | `/web-baslat` · kod · `/web-denetle` · `/web-yukle` |

Aktif faz bitmeden alt faza geçme; `debug_report.json` varsa önce kök nedeni çöz.
