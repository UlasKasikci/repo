# UI tasarım standartları (Webrail)

**Zorunlu.** Dashboard, paneller ve tüm kullanıcı arayüzleri.  
**Kanon ajan:** `web-frontend-specialist` · QA: `qa-gate` `ui_icons` kanalı.

## Kalite barı

Figma seviyesinde üretim: tipografi hiyerarşisi, boşluk ritmi, tutarlı renk token’ları,
erişilebilir kontrast. “AI default” görünüm yasak.

## Yasak — AI klişe görseller

- Neon / cyberpunk / mor-indigo glow / aşırı blur cam efektleri
- Tek kenarlı “AI kart” border’ları (yalnız sol/üst çizgi + boş gövde)
- Mor-beyaz veya krem+terracotta varsayılan tema kopyaları
- Hero’da yüzen badge / sticker / chip yığınları
- Dashboard olmayan sayfada dashboard grid’i

İstisna: markanın kendi design system’i açıkça tanımlıysa ona uy.

## İkonlar

| İzin | Yasak |
|------|--------|
| **SVG** (inline veya `assets/icons/*.svg`) | Emoji (📎 🛒 ✅ 🚀 vb.) UI’da |
| `currentColor` ile boyanabilir SVG | Icon font emoji / Twemoji rastgele |

Dekoratif emoji metin içeriğinde (kullanıcı ürettiği) serbest; **chrome / nav / buton /
dashboard widget ikonu asla emoji olmaz**.

## Bileşen ilkeleri

- Kart: yalnız etkileşim konteyneri gerektiğinde; aksi halde düz layout
- Bir bölüm = bir iş; hero’da istatistik şeridi yok
- Motion: 2–3 bilinçli geçiş; gürültü yok
- Responsive: mobil önce kırılımlar

## Doğrulama

```bash
bash scripts/web/qa-gate.sh <proje>   # ui_icons FAIL → emoji chrome
```
