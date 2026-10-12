# /yama — Küçük düzeltme şeridi (tam P1 yeniden yok)

Hedef: `$ARGUMENTS` (proje; boşsa `.`). `mode=factory` ve faz P3+ / DONE.

## Ne zaman

Tek dosya / dar bug; RBAC-KVKK mimarisi değişmiyor.

## Adımlar

1. `bash scripts/web/status.sh $ARGUMENTS` — mode/faz oku.
2. Discovery/P1’e dönme. `DISCOVERY.md` yeniden yazma.
3. Düzeltmeyi uygula (PDO / CSRF / htmlspecialchars kuralları aynı).
4. `php -l` değişen PHP dosyalarına.
5. `bash scripts/web/qa-gate.sh $ARGUMENTS` — 0E/0W.
6. Gerekirse `/web-yukle` (yalnız PASS sonrası).

## Yasak

- `mode=discovery` iken kod
- Domain genişletmesi → `/web-baslat` / P1
- QA bypass
