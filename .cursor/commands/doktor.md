# /doktor — Webrail Error Doctor (tespit → güvenli düzelt → brief)

Hedef: `$ARGUMENTS` (proje; boşsa `.`).

## Ne zaman

`qa-gate` FAIL, P4, veya “ne bozuk / nasıl düzeltilir?”.

## Adımlar

1. `bash scripts/web/guard.sh doctor $ARGUMENTS` — DENY → fix.
2. `bash scripts/web/doctor.sh $ARGUMENTS --qa-first` — teşhis.
3. Güvenli otomatik: `bash scripts/web/doctor.sh $ARGUMENTS --loop`.
4. Kalan hatalar için **yalnız** `FIX-BRIEF.md` oku ve uygula (tüm qa-report dump yasak).
5. `bash scripts/web/qa-gate.sh $ARGUMENTS` — 0 Error / 0 Warning.
6. Rapor: `doctor-report.json`.

## Yasak

- Discovery modunda kod yazma
- Kanıtsız PASS
- Token şişiren tam dosya dump
