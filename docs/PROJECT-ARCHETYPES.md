# Webrail — Proje arketipleri (esnek ağaç)

**İlke:** Her proje e-ticaret değildir. Sistem brief / DISCOVERY / `project-intent.project_type`
ile **ne gerektiğini** seçer; olmayanı zorlamaz.

## Arketipler

| ID | Tipik brief | Zorunlu (blocker) | Öneri (warn) | Bilinçli hariç |
|----|-------------|-------------------|--------------|----------------|
| `onepage` | tek sayfa, landing, CV | SEO temel | KVKK/çerez (TR) | sepet, ödeme, yorum, RBAC |
| `brochure` | kurumsal, hakkımızda, iletişim | SEO | KVKK | sepet, ödeme, yorum |
| `showcase` | ürün/hizmet **tanıtım**, vitrin, portfolio | SEO | KVKK; isteğe galeri/CRM form | **sepet/ödeme/yorum yok** (varsayılan) |
| `catalog_rfq` | katalog + teklif / sipariş talebi | teklif veya sepet benzeri akış | bildirim | ödeme (çoğu zaman hariç) |
| `ecommerce` | mağaza, shop, satın al, sepet | **sepet/sipariş** + RBAC (üyelik varsa) | **ödeme kararı**, yorum/oylama, fatura | — |
| `webapp` | panel, SaaS, üye alanı, admin | **RBAC** + oturum güvenliği | KVKK, SEO | sepet (iş kuralı yoksa) |

## Algılama sırası (yüksek öncelik kazanır)

1. Açık e-ticaret sinyali → `ecommerce`  
   (`e-ticaret`, `sepet`, `satın al`, `checkout`, `shop`, `ödeme`, `iyzico`…)
2. Teklif / RFQ → `catalog_rfq`
3. Ürün/hizmet **tanıtım** / vitrin / portfolio **ve** satış fiili yok → `showcase`
4. Tek sayfa / landing → `onepage`
5. Login / admin / panel / CRUD → `webapp` (diğerleriyle birleşebilir)
6. Aksi → `brochure`

> **Kritik:** Yalnızca “ürün” veya “katalog” kelimesi ≠ e-ticaret.  
> Vitrinde ürün kartı olabilir; sepet/ödeme **enjekte edilmez**.

## Kaynaklar

- Brief → `plan-from-brief.sh` / `mode from-brief` sinyalleri  
- Dondurma → `.factory/project-intent.json` → `project_type`  
- Denetim → `gap-scan.sh` arketipe göre severity  
- İstisna → kullanıcı onayı (`--allow-no-cart`, PLAN “hariç” satırı)

## S2 notu

Ödeme/yorum **modül paketleri** yalnız `ecommerce` (veya açık kullanıcı isteği) için
katalogda önerilir; `showcase` / `onepage` ağacına zorlanmaz.
