# Gap uyarı vs FAIL — onay matrisi

**İlke:** Arketip + kullanıcı onayı. Showcase/onepage’e e-ticaret zorlanmaz.

| Bulgu | `ecommerce` | `catalog_rfq` | `showcase`/`brochure`/`onepage` | Onay / istisna |
|-------|-------------|---------------|----------------------------------|----------------|
| `cart_missing` | **BLOCKER** | BLOCKER (veya RFQ akışı) | yok | `--allow-no-cart` · PLAN “hariç” |
| `payment_missing` | WARN → proposed | yok (çoğu) | yok | brief’te ödeme yoksa “hariç” |
| `reviews_missing` | WARN → proposed | yok | yok | kullanıcı reddederse PLAN “hariç” |
| `rbac_missing` | üyelik varsa BLOCKER | webapp/üyelik | yalnız webapp | bilinçli public site |
| `seo_missing` | WARN | WARN | WARN (onepage’te soft) | — |
| `kvkk_missing` | WARN (TR) | WARN | WARN | `compliance=none` |

## Akış

1. `gap-scan.sh` → `gap-report.json` (arketip + severity)
2. `gap-inject.sh` → `domain-report.module_matrix` **proposed** (yalnız izinli arketip)
3. `decide.sh` → `modules_to_apply` (payment/reviews yalnız ecommerce)
4. Kullanıcı / PLAN “hariç” → inject atlanır; orchestrate blocker’da kalırsa P1 güncelle

## Kod

- Politika: `docs/PROJECT-ARCHETYPES.md`
- Inject: `scripts/web/gap-inject.sh`
- Decide filtre: `scripts/web/decision.py`
