# Veritabanı adlandırma (Webrail)

**İlke:** Anlam **Türkçe**, yazım **ASCII** (kod ve araçlar kırılmasın).  
İngilizce az olan geliştirici “bu neydi?” demesin; global kelimeler korunur.

## Diyakritik dönüşüm

| Türkçe | ASCII |
|--------|-------|
| ı / İ | i / I |
| ö / Ö | o / O |
| ü / Ü | u / U |
| ğ / Ğ | g / G |
| ş / Ş | s / S |
| ç / Ç | c / C |

Örnek: `ürünler` → **`urunler`** · `açıklama` → **`aciklama`** · `sipariş` → **`siparis`**.

## Tablo adları

Domain tabloları Türkçe-ASCII, `snake_case`, çoğul:

| Anlam | Tablo |
|-------|--------|
| ürünler | `urunler` |
| siparişler | `siparisler` |
| sipariş kalemleri | `siparis_kalemleri` |
| ödemeler | `odemeler` |
| yorumlar | `yorumlar` |
| bildirimler | `bildirimler` |
| kullanıcılar | `kullanicilar` (veya legacy `users`) |
| roller | `roller` (veya legacy `roles`) |

## Sütun adları

- Domain: Türkçe-ASCII — `urun_adi`, `fiyat`, `stok`, `kullanici_id`, `siparis_id`, `okundu`
- **Global / evrensel (değiştirme):**  
  `id`, `title`, `description`, `slug`, `email`, `status`, `created_at`, `updated_at`,  
  `password_hash`, `role_id`, `currency`, `amount`, `provider`, `external_id`, `rating`, `body`

FK: `{tekil_tablo}_id` ASCII — `urun_id`, `siparis_id`, `kullanici_id`.

## Yasak

- Tanımlayıcılarda `ğüşıöçİĞÜŞÖÇ` (qa-gate **FAIL**)
- Karışık dil: `urun_description` yerine ya `urun_aciklamasi` ya global `description`

## Legacy

Fixture / eski projeler: `products`, `orders`, `users` hâlâ tanınır (qa-gate alias).  
**Yeni** modül paketleri Türkçe-ASCII tercih eder.

## Doğrulama

```bash
bash scripts/web/qa-gate.sh <proje>   # sql_ident_ascii kanalı
```
