---
name: yapilacaklar-executor
description: >-
  YAPILACAKLAR.md aktif fazını sırayla uygular; durum günceller; keşfedilen
  eksikleri [EK-YYYYMMDD] ile ekler; L1 subagent doğrulaması ister. /devam-et
  komutu ve kod uygulama oturumlarında kullan.
---

# YAPILACAKLAR Uygulayıcı

## Başlangıç

1. `YAPILACAKLAR.md` oku — aktif faz (`işleniyor`).
2. `zero-hallucination` skill protokolünü uygula.
3. Faz tablosunda ilk `bekliyor` satırı seç.

## Döngü (her görev)

```
 seç → işleniyor (satır) → ajan uygula → L1 doğrula → tamamlandı → sonraki satır
```

1. Satır durumunu tabloda `işleniyor` yap (görev sütunu veya Durum).
2. **Ajan** sütunundaki `.cursor/rules/XX-*.mdc` kuralını uygula.
3. **L1** sütunundaki üst departman perspektifiyle kontrol et; gerekirse `@phase-verifier` subagent.
4. Kabul kriteri sağlanınca satırı `tamamlandı` yap.
5. Fazdaki tüm satırlar `tamamlandı` → faz başlığını `tamamlandı`, sonraki fazı `işleniyor`.

## Keşif protokolü (dinamik faz genişletme)

Uygulama sırasında eksik tespit edilirse:

1. **Keşifler & Dinamik Eklemeler** tablosuna satır ekle: `[EK-YYYYMMDD]`.
2. Uygun faz tablosuna yeni madde ekle (aynı faz veya üst faz — asla atlanmış alt faz).
3. Durum: `bekliyor`.
4. Aktif işi kesme; önce keşif maddesini plana yaz, sonra önceliğe göre uygula.

## Senkronizasyon

- `docs/TODO.md` — YAPILACAKLAR ile uyumlu kısa özet
- `docs/CHANGELOG.md` — tamamlanan faz ADR notu

## Bitiş raporu

Her oturum sonunda:

- Tamamlanan maddeler listesi
- Aktif faz + sıradaki madde
- Eklenen `[EK-*]` maddeler
- Blokörler (Mimar aksiyonu)
