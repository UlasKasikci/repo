# Cursor Snapshots — Webrail handoff (geçici)

IDE oturumları arasında **dosya tabanlı** kanıt; sohbet hafızasına güvenilmez.

## Klasörler (gitignore — runtime)

| Klasör | Üreten | İçerik |
|--------|--------|--------|
| `mcp/` | MCP kullanan ajan | Araştırma özeti JSON/MD |
| `recovery/` | manuel / doctor notu | Kısa kurtarma handoff (opsiyonel) |

Şablonlar (repoda):

- [`HANDOFF.template.json`](HANDOFF.template.json) — MCP / araştırma handoff  
- [`RECOVERY.template.json`](RECOVERY.template.json) — QA FAIL / yarım iş kurtarma  

## Zorunlu protokol

MCP veya uzun araştırma çıktısı sohbette taşınmaz:

```text
.cursor/snapshots/mcp/{agent}-{YYYYMMDD-HHMMSS}.json
```

Son işaret: `mcp/LATEST.handoff.json` (her yazımda güncellenir).  
Sonraki ajan önce bunu veya `RUN-STATUS.md` + `PHASE-LOG.md` okur.

## Webrail handoff (kanonik)

Gradle / Maestro / Android recovery **yok**. Kullan:

```bash
bash scripts/web/status.sh .
bash scripts/web/phase-log.sh . "özet" "sonraki" "cevap"
# oku: RUN-STATUS.md · PHASE-LOG.md · docs/IDE-HANDOFF.md
```

QA FAIL → `bash scripts/web/doctor.sh . --loop` → yalnız `FIX-BRIEF.md`.

## Git

Runtime snapshot dosyaları `.gitignore` dışındadır. Commit’te yalnız bu README + şablonlar kalır.
