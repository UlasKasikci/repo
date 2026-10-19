# MCP kurulumu (Webrail — isteğe bağlı)

Android / Gradle / emülatör MCP **yok**. Yalnız web araştırma ve (fabrika deposunda) GitHub.

## Dosyalar

| Dosya | Rol |
|-------|-----|
| `.cursor/mcp.required.json` | Önerilen sunucular (sürüm etiketi) |
| `.cursor/mcp.json.example` | Yerel `mcp.json` örneği |
| `.cursor/mcp.json` | Yerel (gitignore — commit etme) |

## Kullanım

1. Örneği kopyala: `cp .cursor/mcp.json.example .cursor/mcp.json`
2. Cursor’da MCP’yi etkinleştir
3. Çıktıyı sohbete yapıştırma → `.cursor/snapshots/mcp/` veya `docs/findings/` yaz  
   Şablon: `.cursor/snapshots/HANDOFF.template.json`

Kural: `.cursor/rules/06-mcp-orchestrator.mdc`
