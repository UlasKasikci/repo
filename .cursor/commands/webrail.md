# /webrail — Tek giriş (Şerit A → P1)

Hedef: `$ARGUMENTS` (proje yolu; boşsa sor). Brief için sohbette `--brief "..."` belirt.

## Amaç

Saf IDE kadar hızlı başla; kapıları kaldırma. İçerde:

`preflight` → `bootstrap` → `from-brief|promote` → `state start` → `status`

## Çalıştır

```bash
# Fabrika kökünden (ilk kez)
bash scripts/web/preflight.sh   # webrail.sh da çağırır
bash scripts/web/webrail.sh ../musteri-adi --yes --brief "X için CRUD+auth+KVKK panel"

# Brief yoksa keşifte kalır (/kesfet)
bash scripts/web/webrail.sh ../musteri-adi --yes
```

## Sonraki

1. `bash scripts/web/status.sh $ARGUMENTS` — mode/faz/next
2. `/web-baslat` — domain-report + decide
3. P2: `module-apply` sonra `P2_HUMAN_ASSIST=true` orchestrate (önerilen)
4. `/web-denetle` → `/web-yukle`

## Kısıt

- Discovery bypass yok; `--brief` iz bırakır (`DISCOVERY.md` + measure).
- QA 0E/0W ve mode kilidi gevşetilmez.
