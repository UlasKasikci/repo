---
name: seo-basics
description: Temel SEO iskeleti — robots.txt, sitemap.xml, canonical/meta description, semantik başlık; her web projesinde P2'de uygula.
---

# SEO Basics

**Durum:** READY · **Kapı:** yapı + SEO dosya varlığı · **Karar:** modül `seo`

## Dosya sözleşmesi

| Dosya | İçerik |
|-------|--------|
| `robots.txt` | `Sitemap: https://<host>/sitemap.xml` + Allow/Disallow |
| `sitemap.xml` | En az ana sayfa + yasal sayfalar URL’leri |
| Layout `<head>` | `meta name="description"`, `<title>`, isteğe bağlı `link rel="canonical"` |
| Semantik HTML | tek `h1`, landmark `main`/`nav`/`footer` |

## Uygulama sırası

1. `robots.txt` + `sitemap.xml` yaz (proje adı / domain domain-report’tan).
2. Layout partial’da description + title değişkenleri.
3. Ana sayfa ve legal sayfalarda benzersiz title/description.
4. Paketleme sonrası canlıda canonical host’u güncelle.

## Yasak

- Boş description / “lorem” title.
- Sitemap olmadan “SEO tamam” demek.
