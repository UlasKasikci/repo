# Cursor Snapshots — Ajan Handoff & Terminal Kanıt

Cursor Agent oturumları arasında **dosya tabanlı handoff** ve **terminal kanıtı** için geçici durak.

## Klasörler

| Klasör | Üreten | İçerik |
|--------|--------|--------|
| `build/` | `scripts/gradle-build-loop.sh` | Gradle `--stacktrace` logları, `LATEST.gradle.log` |
| `recovery/` | `scripts/state-recovery.sh` | Checkpoint meta, recovery handoff |
| `maestro/` | `scripts/run-maestro.sh` | E2E test çıktıları, `LATEST.maestro.log` |
| `mcp/` | MCP kullanan ajanlar | Browser/GitHub araştırma özeti (JSON/MD) |

## MCP handoff protokolü (ZORUNLU)

MCP (Browser, GitHub, Fetch) ile veri toplayan ajan **sohbet hafızasına güvenmez**. Çıktıyı dosyaya yazar:

```
.cursor/snapshots/mcp/{agent}-{YYYYMMDD-HHMMSS}.json
```

Şablon: [`HANDOFF.template.json`](HANDOFF.template.json)

Son handoff: `mcp/LATEST.handoff.json` (her yazımda güncellenir)

**Sonraki ajan** devam etmeden önce `LATEST.handoff.json` veya ilgili snapshot'ı **okur**.

## Gradle build kanıtı (F3+)

Android kod değişikliğinden sonra:

```bash
./scripts/gradle-build-loop.sh
```

Başarısızsa Agent **`LATEST.gradle.log`** okur, düzeltir, tekrar çalıştırır.  
F3+ faz satırı `tamamlandı` **yapılmaz** build PASS olmadan.

## State recovery (truncation / yarım edit)

```bash
./scripts/state-recovery.sh --checkpoint
./scripts/state-recovery.sh --recover
./scripts/state-recovery.sh --status
```

Handoff: `recovery/LATEST.recovery.handoff.json` — bkz. [`docs/STATE_RECOVERY.md`](../../docs/STATE_RECOVERY.md)

## Git

Runtime snapshot'lar `.gitignore` ile commit dışıdır. Yalnızca bu README ve şablonlar repoda kalır.
