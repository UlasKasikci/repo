# /web-faz — State Graph + status panosu

Aktif fazı ve kanıt dosyalarını okur — salt okunur.

```bash
bash scripts/web/status.sh $ARGUMENTS
bash scripts/web/state.sh status $ARGUMENTS
bash scripts/web/guard.sh matrix $ARGUMENTS
```

QA FAIL / P4:

```bash
bash scripts/web/doctor.sh $ARGUMENTS --loop   # /doktor
```

| Alan | Değer |
|------|-------|
| Faz | P1–P5 / HALT |
| Retry | n / 3 (4. fail HALT) |
| QA / doctor | qa-report · doctor-report · FIX-BRIEF |
| Sonraki | `/web-baslat` · `/doktor` · `/web-denetle` · `/web-yukle` |

`debug_report.json` varsa önce kök neden; kanıtsız PASS yok.
