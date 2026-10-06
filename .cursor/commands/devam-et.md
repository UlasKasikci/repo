# /devam-et — Aktif Fazdan Devam Et

`YAPILACAKLAR.md` aktif fazındaki sıradaki `bekliyor` maddeden devam et.

## Ön koşul

- `YAPILACAKLAR.md` mevcut — yoksa önce `/baslat`
- Skill: `zero-hallucination` + `yapilacaklar-executor`

## Akış

1. `YAPILACAKLAR.md` oku → aktif faz (`işleniyor`) + ilk `bekliyor` satır.
2. Satırı `işleniyor` yap; ilgili `.cursor/rules/` ajanını uygula.
3. İş bitince `@phase-verifier` subagent ile L1 doğrula.
4. Kabul sağlanınca `tamamlandı`; faz bittiyse sonraki fazı `işleniyor`.
5. Keşif varsa `[EK-YYYYMMDD]` ekle (skill: yapilacaklar-executor § Keşif).
6. `python3 scripts/governance/validate-yapilacaklar.py`

## Rapor

- Tamamlanan maddeler (bu oturum)
- Aktif madde
- Eklenen keşif maddeleri
- Blokörler
