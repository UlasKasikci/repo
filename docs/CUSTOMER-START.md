# Müşteri / Proje Açılış Protokolü — Webrail

**Amaç:** Hangi IDE (Cursor, OpenCode, Claude Code, Antigravity) veya personel
olursa olsun aynı standartlarla, halüsinasyonsuz, kaldığı yerden devam.

**Kanonik depo:** https://github.com/UlasKasikci/repo  
**Ücretli JEV yok.** Karar mantığı açık kaynak: `scripts/web/decide.sh`.

---

## 0) Fabrika hazır mı? (zorunlu)

```bash
cd ~/webrail   # veya bu repo kökü
bash scripts/web/preflight.sh
# PREFLIGHT: READY görmeden müşteriye geçme
```

## 1) Fabrikayı kaynak tut, müşteri klasörüne bootstrap et

```bash
# Webrail kaynağı (bir kez / güncel tut)
git clone https://github.com/UlasKasikci/repo.git ~/webrail
cd ~/webrail
bash scripts/web/preflight.sh

# Müşteri projesi — ASLA fabrika köküne yazma
bash scripts/web/bootstrap-project.sh ../musteri-adi --yes
cd ../musteri-adi
```

Bootstrap: kontratlar, ajanlar, scriptler, skills + `DISCOVERY.md` + `mode=discovery`.  
**Kopyalanmaz:** `tests/`, `.github/`, `e2e-runs/`, self-test (şişme yok).

---

## 1b) Şerit A — saf IDE keşfi (kod YOK)

Bootstrap sonrası fabrika kapıları kilitli (`mode=discovery`). Önce ucuz keşif:

```bash
# IDE: /kesfet   veya elle DISCOVERY.md doldur
# **Proje adı:** satırı zorunlu (şablon yer tutucusu kabul değil)
bash scripts/web/measure.sh . discovery_minutes 15 A0
bash scripts/web/mode.sh promote .   # discovery → factory
```

`state.sh start` / `orchestrate` / `decide` **promote olmadan RED**.

---

## 2) State + karar + handoff (factory)

```bash
bash scripts/web/mode.sh status .    # mode=factory olmalı
bash scripts/web/state.sh start .
# P1 domain-report üret (IDE /web-baslat veya orchestrate)
bash scripts/web/orchestrate.sh . --auto   # veya manuel P1
bash scripts/web/decide.sh .               # Decision Layer → decision.json + RUN-STATUS.md
```

P2 önerisi: saf IDE taslak + Webrail QA — `P2_HUMAN_ASSIST=true` ile orkestrasyon.

Her oturum başı (zorunlu okuma sırası):

1. `DISCOVERY.md` + `.factory/mode.json` (mode?)
2. `RUN-STATUS.md`
3. `.factory/web-state.json`
4. `.factory/domain-report.json`
5. `.factory/decision.json`

---

## 3) IDE fark etmez — aynı kapılar

| İş | Cursor | OpenCode | Claude / Antigravity / terminal |
|----|--------|----------|----------------------------------|
| Başlat | `/kur` `/web-baslat` | `/kur` `/web-baslat` | `state.sh` + `orchestrate.sh` |
| Karar | `decide.sh` | `decide.sh` | `decide.sh` |
| QA | `/web-denetle` | `/web-denetle` | `qa-gate.sh` |
| Paket | `/web-yukle` | `/web-yukle` | `package-yukleme.sh` |

Antigravity: `antigravity.yaml` → aynı `docs/WEB-EDITION.md` + state komutları.

---

## 4) Token ekonomisi (JEV-mantık, ücretsiz)

| Mekanizma | Dosya |
|-----------|--------|
| Ucuz karar / pahalı üretim ayrımı | `decide.sh` → `decision.json` |
| Modül önce, LLM sonra | `.factory/modules/catalog.json` + skills |
| Bağlam budama | `context_allowlist` |
| Model katmanlama | `MODEL_P1` / `MODEL_P2` / `MODEL_P4` |
| Sepetsiz domain | `qa_gate_extra: --allow-no-cart` (karar önerir) |

---

## 5) Personel değişimi

Yeni kişi/IDE:

```bash
cat RUN-STATUS.md
bash scripts/web/state.sh status .
# kaldığı fazdan:
bash scripts/web/orchestrate.sh . --auto
```

`RUN-STATUS.md` ve `.factory/*` commit’lenir — sohbet hafızasına güvenilmez.
