# DISCOVERY — Keşif brifi (Şerit A · kod YOK)

> **Kural:** Bu dosya dolmadan ve `.factory/mode.json` → `factory` olmadan
> `core/`, `views/`, `SQL/` üretim kodu yazılmaz.
> Saf IDE burada ucuz kalır; Webrail kapıları **koddan önce** açılır.

**Proje adı:** _(buraya yaz — promote için zorunlu)_  
**Tarih:**  
**Operatör / IDE:** Cursor · OpenCode · Claude · Antigravity  

---

## 1. İş özeti (3–5 cümle)

<!-- Müşteri ne istiyor? Kim kullanacak? -->

## 2. Kapsam

| Dahil | Hariç (bilinçli) |
|-------|------------------|
| | |

## 3. Varlıklar (taslak tablo adları)

- 

## 4. Roller

- admin /
- user /

## 5. Modül sinyalleri (P1’e girdi)

| Modül | Gerekli? | Not |
|-------|----------|-----|
| auth / rbac | evet / hayır | |
| admin CRUD | | |
| sepet / sipariş | | |
| KVKK / GDPR | | |
| SEO | evet | |

## 6. Riskler / açık sorular

1. 

## 7. Keşif metrikleri (elle veya measure.sh)

- Keşif süresi (dk):  
- Tahmini token (opsiyonel):  

```bash
bash scripts/web/measure.sh . discovery_minutes <N> A0
```

## 8. Fabrikaya geçiş checklist

- [ ] Bölüm 1–6 doldu (placeholder yok)
- [ ] Kod dosyası yazılmadı (`core/` `views/` `SQL/` yok veya boş)
- [ ] `bash scripts/web/mode.sh promote .` çalıştırılacak

**Sonraki:** `bash scripts/web/mode.sh promote .` → `state.sh start` → `/web-baslat`
