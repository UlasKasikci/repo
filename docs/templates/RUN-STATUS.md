# RUN-STATUS — Webrail handoff (şablon)

> Canlı dosya proje kökünde `RUN-STATUS.md` olarak `run-status.sh` ile üretilir.
> Bu şablon yalnızca referanstır.

| Alan | Değer |
|------|-------|
| Güncelleme (UTC) | — |
| Faz | P1 / P2 / P3 / P4 / P5 / DONE / HALT |
| Status | in_progress / done / halted |
| Decision modülleri | — |

## Sonraki adımlar

- `bash scripts/web/decide.sh .`
- `bash scripts/web/orchestrate.sh . --auto`
