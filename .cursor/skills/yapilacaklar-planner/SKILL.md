---
name: yapilacaklar-planner
description: >-
  Mimar promptunu bina metaforlu YAPILACAKLAR.md faz planına dönüştürür. /baslat
  komutu, yeni proje, init-new-app sonrası veya boş YAPILACAKLAR durumunda kullan.
---

# YAPILACAKLAR Planlayıcı

## Girdi

Mimarın doğal dil promptu (ürün tanımı, hedefler, kısıtlar).

## Çıktı

Güncellenmiş `YAPILACAKLAR.md`:
- Kaynak prompt satırı dolu
- F0–F8 fazları (şablondan)
- Prompta özel **F7** ve **F1** maddeleri eklenmiş
- Tüm maddeler: Ajan · L1 · Kabul · Durum (`bekliyor` / `işleniyor` / `tamamlandı`)

## Algoritma

1. `templates/YAPILACAKLAR.template.md` oku.
2. `bash scripts/governance/init-yapilacaklar.sh "<prompt özeti>"` çalıştır (veya eşdeğer subst).
3. Prompttan türet:
   - **F1:** pazar/ürün maddeleri (CPO)
   - **F7:** feature WP satırları (CDID → Android)
   - **F6:** analytics gerekiyorsa AID maddeleri
4. F0'ı `işleniyor`, diğer fazları `bekliyor` bırak.
5. `python3 scripts/governance/validate-yapilacaklar.py` çalıştır.
6. `docs/00-INDEX.md` Aktif Faz satırını F0 yap.

## Keşif alanı

Plan sonunda boş **Keşifler & Dinamik Eklemeler** tablosunu koru.

## Metafor (Mimara özet)

| Faz | Bina |
|-----|------|
| F0 | Temel |
| F1–F2 | Taşıyıcı |
| F3–F4 | Kabuk |
| F5–F6 | Tesisat & sayaç |
| F7 | İç mekan |
| F8 | Anahtar teslim |
