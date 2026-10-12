# /kesfet — Şerit A: saf IDE keşfi (kod YOK)

Hedef: `$ARGUMENTS` (boşsa `.`). Webrail kapıları henüz kapalı (`mode=discovery`).

## Amaç

Ucuz keşif: kapsam, varlıklar, roller, KVKK/sepet sinyalleri.  
**Yasak:** `core/`, `views/`, `SQL/`, `index.php` üretim kodu yazmak.

## Adımlar (sırayı değiştirme)

1. `bash scripts/web/preflight.sh` (fabrika kökünde; bir kez).
2. Hedef yoksa: `bash scripts/web/bootstrap-project.sh $ARGUMENTS --yes`
3. `DISCOVERY.md` aç (yoksa `docs/templates/DISCOVERY.md` kopyala / `mode.sh init`).
4. Bölüm 1–6’yı doldur. **Proje adı** satırı zorunlu.
5. Süre ölç: `bash scripts/web/measure.sh $ARGUMENTS discovery_minutes <N> A0`
6. Özet sun: dahil/hariç, riskler. Kod yazdığını iddia etme.
7. Sonraki komut: `bash scripts/web/mode.sh promote $ARGUMENTS` → sonra `/web-baslat` veya `state.sh start`.

## Kısıt

- `state.sh start` / `orchestrate` / `decide` discovery’de **RED**.
- P2 üretimi yalnız `mode=factory` + hybrid önerilir (`P2_HUMAN_ASSIST=true`).
