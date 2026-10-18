# Webrail özgünlük kesiti — Error Doctor (2026-10-19)

## Dış kaynaklar (incelendi, kör kopyalanmadı)

| Kaynak | Ne sunuyor | Webrail kararı |
|--------|------------|----------------|
| [DevelopersGlobal/ai-agent-skills](https://github.com/DevelopersGlobal/ai-agent-skills) | 30 süreç skill, 8 kategori anatomisi | İlke: Verification + gate; 30 skill’i taşımadık |
| [skillagent.dev](https://skillagent.dev/) | 15k skill/rule dizini | Katalog şişmesi ≠ denetim |
| [antigravity-awesome-skills](https://github.com/sickn33/antigravity-awesome-skills) | 1800+ installable SKILL.md | Webrail DNA’sına uymaz; token artışı |
| [wshobson/agents](https://github.com/wshobson/agents) | 200 ajan / 185 skill multi-harness | Ajan çoğaltma yasak (tek onay) |

## Kullanıcı hedefi ↔ boşluk

| İstek | Önceki boşluk | Bu tur |
|-------|--------------|--------|
| Full kontrollü | guard + state vardı | aynı |
| Kendini denetleyen | qa-gate 14 kanal | aynı |
| Token azaltma | decide/module-apply | **FIX-BRIEF** — LLM’e dump yok |
| Hata bul + düzelt | yalnız debug_report metni | **`doctor.sh`**: eşle → safe apply → loop → brief |
| Bana ait repo | fabrika+customer kilit | doctor Webrail-özgün (katalogda yok) |

## Mimari

```text
qa-gate FAIL → doctor.sh
  ├─ doctor-recipes.json (önek → tarif)
  ├─ --apply / --loop  → sql-dump, fixture, module files (LLM yok)
  └─ FIX-BRIEF.md      → yalnız kalan BRIEF tarifler (dar LLM)
```

İlke (önceki mimar kesiti ile aynı): **skill ekle ancak script kapısına bağlanırsa.**  
`error-doctor` skill’i `doctor.sh` sarmalayıcısıdır; bağımsız “düşünce tiyatrosu” değildir.
