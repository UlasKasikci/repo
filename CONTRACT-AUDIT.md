# CONTRACT-AUDIT.md — K4 Kontrat Tamlığı Denetimi (A1 Öncesi)

**Tarih:** 2026-10-09 · **Kural:** K4 — "Araştırma yasağı koymadan önce kontratların
eksiksiz olduğunu doğrula. Eksik kontrat + yasak = sessizce yanlış üretim."
**Kapsam:** P2'nin (web-core-engineer) ihtiyaç duyduğu her bilgi, A1 whitelist'i
sonra **yalnızca** `.factory/domain-report.json` + `.factory/contracts/*.json` +
iskelet varlık kontrolünden okunabilecek. Bu kaynaklar eksikse A1 uygulanamaz.

**Yöntem:** P2'nin ihtiyacı → mevcut kaynak (alan/kanıt) → durum → karar.
Doğrulanan kod yolları: `orchestrate.sh:p1_gate_ok` (şema + `domain-check.py`),
`qa-gate.sh:domain_report` (yalnız `domain-check.py` — şema DEĞİL, K6 korunur),
`p2_prompt` girdi bağları.

## Denetim Tablosu

| # | P2 ihtiyacı | Bugünkü kaynak | Durum | Karar |
|---|-------------|----------------|-------|-------|
| 1 | Modül listesi (ne var/ne yok) | `module_matrix[]` (≥4 hücre, gate + semantik denetimli) | **VAR** | dokunma |
| 2 | Auth/RBAC modeli | `roles[]` + `module_matrix.rbac` + `security_context[]` | **VAR** | dokunma |
| 3 | DB tablo/kolon bilgisi | `sql_draft.tables[]` (ad) + `entities[].fields[]` (kolon, **şemada opsiyonel**) | **KISMİ** | `fields` her entity için **required** yapılır + P1 prompt'a "her entity için fields[]" zorunluluğu |
| 4 | API endpoint listesi | **YOK** (hiçbir alan route/method/auth içermiyor) | **EKSİK** | `api_endpoints[]` eklendi (required; API yoksa `[]` — boş da olsa açık karar) |
| 5 | Dosya manifesti (P2'nin hedef dosyaları) | **YOK** | **EKSİK** | `file_manifest[]` eklendi (required: `{path, purpose}`, ≥1) |
| 6 | QA kabul kriterleri (qa-gate ne kontrol eder) | **YOK** — att3 tam buradan spiral'e girdi: `qa-gate.sh`'i okuyup "precise acceptance contract" aradı | **EKSİK** | `acceptance_criteria[]` eklendi (required, ≥1 string) — A1 yasağından SONRA bilginin TEK kaynağı |
| 7 | KVKK/GDPR kapsamı | `compliance` (intent'ten, prompt'ta zorunlu yazım) + kvkk hücresi | **VAR** | dokunma |
| 8 | Teknik konvansiyonlar (REST hata şeması vb.) | `docs/WEB-EDITION.md` §4 — **A1'de okumak yasak** | **ÇAKIŞMA** | kontrat proje-özel değil; konvansiyon **agent md'ye satır içi gömüldü** (her iki IDE), dosya referansı kaldırıldı |
| 9 | P3/P5 gate beklentileri | `p3/p5-*.schema.json` + orchestrate kodu | **VAR** (P2 kullanmaz — gate'ler orchestrate'te) | dokunma (K7) |

## Eklenen Alanlar (şema: `p1-domain-report.schema.json`)

```json
"file_manifest":       [{ "path": "...", "purpose": "..." }]   // required, minItems 1
"acceptance_criteria": ["qa-gate 0 Error/0 Warning: ..."]       // required, minItems 1
"api_endpoints":       [{ "path": "/api/...", "method": "GET|POST|PUT|DELETE", "auth": "..." }]
                                                                   // required (yoksa [])
// entities[].items.required: ["name", "fields"]  (fields artık zorunlu)
```

- `additionalProperties: true` **KORUNDU** (K7/dokunulmayacaklar).
- `required[]` bu üç alanla genişletildi — **P1 prompt'unda da zorunlu listeye
  eklendi** (kanal: prompt → şema → `p1_gate_ok` doğrulaması).
- **qa-gate DEĞİŞMEDİ** (K6): `domain_report` kanalı yalnız `domain-check.py`
  çalıştırır; şema doğrulaması yalnız orchestrate P1 kapısında. Yeni QA
  kontrolü eklenmedi, mevcut kontrol sıkılaştırılmadı.

## Fixture Etkisi (self-test)

Şema `required[]` genişlediği için bilinçli P1 çıktıları da güncellendi
(4 fixture): step 10 tam-zincir, step 12 hollow, step 12 phantom, step 21 stub.
Fixture'lar "bilinçli P1 çıktısı" olduğundan güncelleme K5'e aykırı DEĞİL —
eski alanlar silinmedi, yalnız zorunlu alanlar eklendi.

## Sonuç

**A1'e ENGEL YOK.** 6 eksik/çakışmadan 5'i bu denetimde kapatıldı (3 şema alanı
+ 1 satır içi konvansiyon + 1 prompt zorunluluğu). Kalan açık madde yok:
A1 whitelist + QUESTIONS.json çıkış kapısı uygulanabilir.

## Sonraki Tur Notu (K8 — buraya yazıldı, unutulmasın)

P2 whitelist'i iskelet için "yalnız VARLIK kontrolü, içerik okuma değil"
kapsamında tanımlandı. Q1 bulgusu (c sınıfı: att1 att0 dosyalarını okuyup
düzenledi → kısmi yatırım) ile **çakışma riski**: retry'da "devam et" modeli
iskelet içeriğini okumayı gerektirebilir. Bu gerilim A1 E2E'sinde izlenecek;
gerekirse whitelist'e "önceki denemenin yazdığı dosyalar (oturum 1 kez)"
açılır — K8 gereği burada kayıtlıdır, sessizce unutulmaz.
