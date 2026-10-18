# IDE Handoff — Webrail (OpenCode / Antigravity / Claude → Cursor)

**Amaç:** Ucuz IDE’de başla, Cursor PRO’da bitir/paketle — **aynı kalite**, sohbet hafızasına güvenme.

## Ortak omurga (her IDE)

```text
/kesfet|from-brief → promote → P1 domain-report → decide → module-apply
→ P2 kod → P3 qa-gate → (FAIL: doctor --loop) → P5 Yukleme/
```

Kanıt dosyaları (zorunlu okuma sırası):

1. `RUN-STATUS.md`
2. `PHASE-LOG.md`
3. `.factory/web-state.json` · `mode.json` · `workspace-role.json`
4. `.factory/domain-report.json` · `decision.json`
5. `qa-report.json` / `doctor-report.json` / `FIX-BRIEF.md`

## Tipik bütçe yolu

| Adım | IDE önerisi | Neden |
|------|-------------|--------|
| Keşif + P1 + decide + module-apply | OpenCode / Antigravity / Claude | Ucuz; paket kopya token düşürür |
| P2 iskelet (hybrid) | Aynı veya Cursor | `P2_HUMAN_ASSIST=true` |
| P3 QA + doctor + P5 paket | **Cursor PRO** | Derin düzeltme + paket disiplini |

## Oturum başı (hedef IDE’de ilk mesaj)

```bash
bash scripts/web/status.sh .
cat RUN-STATUS.md PHASE-LOG.md 2>/dev/null
bash scripts/web/guard.sh matrix .
```

Ajan: “Önce bu dosyaları oku; sohbet özetine uyma.”

## Oturum sonu (zorunlu MD)

`PHASE-LOG.md` sonuna ekle:

```markdown
### YYYY-MM-DD HH:MM · <IDE> · faz=<Px>
- Yapılan: …
- Kanıt: <dosya>
- Kalan: …
- Sonraki IDE için: …
```

`bash scripts/web/run-status.sh .` — RUN-STATUS yenile.

## Yasak

- Android / YAPILACAKLAR / Gradle planı
- Fabrika remote’una push (customer-app)
- Kanıtsız “bitti / PASS”
- Tam `qa-report` dump (token) — doctor `FIX-BRIEF` kullan

## Komut parity (çekirdek)

| İş | Cursor | OpenCode | Claude / Antigravity |
|----|--------|----------|----------------------|
| Giriş | `/webrail` | `/webrail` | `webrail.sh` |
| Keşif | `/kesfet` | `/kesfet` | `mode.sh from-brief` |
| P1 | `/web-baslat` | `/web-baslat` | orchestrate + decide |
| Doctor | `/doktor` | `/doktor` | `doctor.sh --loop` |
| QA | `/web-denetle` | `/web-denetle` | `qa-gate.sh` |
| Paket | `/web-yukle` | `/web-yukle` | `package-yukleme.sh` |
| Status | `/web-faz` | `/web-faz` | `status.sh` |
