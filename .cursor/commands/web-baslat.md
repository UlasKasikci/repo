# /web-baslat — P1 Domain & Scope Validation

State Graph'in başlangıç kapısı (Agent 1 · `25-web-domain-architect`).

## Sıra

0. **Proje henüz hiç yoksa** iskeleti kur:

```bash
bash scripts/web/bootstrap-project.sh <hedef>   # dry-run (plan) → onayla --yes
```

   Dolu hedefe `--force`. İlk commit `bootstrap from app-fabrika@<hash>` fabrika izini
   taşır. Bootstrapped boş projede ilk qa-gate P2 öncesi **kasıtlı FAIL** verir
   (yapısal dosyalar + phpstan/phpunit yapılandırması zorunlu) — beklenen durumdur.

1. State durumu:

```bash
bash scripts/web/state.sh status || bash scripts/web/state.sh start .
```

   - State yoksa `start` (P1, retry=0); varsa fazı oku — P1 değilse `/web-faz` kullan.

2. **Proaktif domain denetimi** (`25-web-domain-architect.mdc` listesi):
   - `users` → `role_id`/`permissions` + rol seed'i (yoksa enjekte et)
   - katalog → sepet/sipariş/teklif (yoksa öner + onay iste)
   - ödeme/bildirim/SEO/KVKK eksiklerini öner
3. Deterministik kanıt (proje dizini varsa):

```bash
bash scripts/web/qa-gate.sh . ; cat qa-report.json
```

   (Bu koşu P1 analiz kanıtıdır; faz geçişi kaydı için `/web-denetle` kullanılır.)

4. P1 raporunu **zorunlu artefakt olarak yaz**: `<proje>/.factory/domain-report.json`
   (UTF-8 JSON; şema: `.factory/contracts/p1-domain-report.schema.json` — `module_matrix`
   ≥4 modül; her hücrede `present|missing|injected|proposed` + **dolu** `evidence`
   (kaynak ref: `SQL/veritabani.sql:users`) + `justification` (≥20 kr gerekçe);
   şablon/boş matrix `qa-gate.sh` `domain_report` kontrolünde FAIL olur) ve özet:
   varlıklar, roller, enjekte edilen modüller, onay bekleyen istisnalar, edge case'ler,
   security context, SQL şema taslağı.

   `bash scripts/web/orchestrate.sh .` bu artefaktı şemayla doğrular; yoksa P2'ye
   beklemede kalır (exit 3) veya geçersiz raporda hata verir (exit 1).

## Faz dondurma (kullanıcı onayı)

Rapor onaylanınca (requirements-frozen):

```bash
bash scripts/web/state.sh advance .
```

**Kural:** P1 raporu dondurulmadan kod üretimi (P2) başlamaz.
