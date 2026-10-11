# RUN-REPORT — <TUR/ÜRÜN ADI> · <domain> (gerçek proje koşusu)

> Şablon: `docs/templates/RUN-REPORT-template.md` — her gerçek proje koşusunda
> kopyalanır ve doldurulur. Ölçümler `.factory/metrics.jsonl`'den okunur
> (`bash scripts/web/measure.sh` ile yazılan `kind: measure` satırları dâhil).
> Referans yapı: `.factory/test-runs/20261011T005542Z/RUN-REPORT-2.md`.

**Tarih:** <YYYYMMDD-HHMMZ> · **Fabrika sürümü:** <tag/commit> · **Sonuç:** <PASS/FAIL/HALT>
**Özet (2-3 cümle):** <hangi fazlar hangi denemede geçti, en kritik engel ve çözümü>

---

## 1. Faz Zamanı

| Faz | Komut | Süre | Deneme | Sonuç | Not |
|-----|-------|------|--------|-------|-----|
| Bootstrap (/kur eşdeği) | `bash scripts/web/bootstrap-project.sh <hedef> --yes` | <X s / measure: kur_duration_s> | 1 | PASS | |
| P1 Domain | `orchestrate.sh --auto` (giriş) | <s> (latency_ms) | 1 | PASS/FAIL | module_matrix: <n> modül |
| P2 Code | manel iskelet + `state.sh advance` | <X dk (measure: manual_p2_min)> | 1 | PASS | hybrid: phase_human_assist=true |
| P3 QA | `qa-gate.sh` döngüsü | <s> | <9→…→0> | PASS | <n>/14 kanal |
| P5 Package | `package-yukleme.sh` + smoke | <s> | 1 | PASS | smoke: <PASS/WARN> |
| **Toplam** | | **<dk>** | **<LLM deneme sayısı>** | **<state>** | DONE mı? |

## 2. Sıfırdan Karşılaştırma (varsa önceki koşuyla)

| Metrik | Önceki | Bu koşu | Δ |
|--------|--------|---------|---|
| Toplam süre | <dk> | <dk> | <%> |
| Token (in/out) | <n>/<n> | <n>/<n> | <%> |
| LLM deneme sayısı | <n> | <n> | |
| P3 hata düzeltme turu | <n> | <n> | |
| P2 auto yazım oranı | <n>/10 | <n>/10 | hybrid mi? |

Kaynak: `<proje>/.factory/metrics.jsonl` → agent satırları (`tokens`, `rc`,
`latency_ms`) + measure satırları (`kur_duration_s`, `manual_p2_min`,
`phase_human_assist`).

## 3. Manuel Müdahaleler (P2_HUMAN_ASSIST / elle yazımlar)

| Ne | Neden (otomatik neden yetersiz) | Süre | Sonuç dosyası |
|----|--------------------------------|------|---------------|
| P2 iskeleti manel | P2 auto write 0/10 (Tur 2-10) | <X dk> | `index.php`, `core/`, `views/`, `SQL/` |
| <diğer> | | | |

## 4. P3 Düzeltme Yolculuğu (QA gate gerçek davranışı)

| Tur | Hata (qa-report.json) | Düzeltme | Kanal |
|-----|----------------------|----------|-------|
| 1 | `<hata metni>` | `<dosya/satır düzeltmesi>` | <kanal> |
| … | | | |
| n | 0 Error 0 Warning | — | **14/14 PASS** |

## 5. Bulgular / Kararlar

- <yeni finding — `docs/findings/FINDINGS-TUR*-*.md` varsa referans>
- <K/şartname etkisi var mı: K6/K7/state graph değişmedi mi?>

## 6. Öneriler (bir sonraki koşuya)

1. <adım/adım, ölçülebilir>
2. <ölçüm alanı eksikse: `measure.sh` ile eklenecek alan>
