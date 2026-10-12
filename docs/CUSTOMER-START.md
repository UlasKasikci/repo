# Müşteri / Proje Açılış Protokolü — Webrail

**Amaç:** Hangi IDE (Cursor, OpenCode, Claude Code, Antigravity) veya personel
olursa olsun aynı standartlarla, halüsinasyonsuz, kaldığı yerden devam.

**Kanonik depo:** https://github.com/UlasKasikci/repo  
**Ücretli JEV yok.** Karar mantığı açık kaynak: `scripts/web/decide.sh`.

**Normal yol:** tek giriş `/webrail` veya `webrail.sh` — alt komutlar ileri seviye.

---

## 0) Fabrika hazır mı? (zorunlu)

```bash
cd ~/webrail   # veya bu repo kökü
bash scripts/web/preflight.sh
# PREFLIGHT: READY görmeden müşteriye geçme
```

## 1) Tek giriş (önerilen)

```bash
git clone https://github.com/UlasKasikci/repo.git ~/webrail
cd ~/webrail

# Brief ile: DISCOVERY doldur + promote + state P1 (fabrika köküne YAZMA)
bash scripts/web/webrail.sh ../musteri-adi --yes \
  --brief "Stok takip paneli: kullanıcılar, ürünler, admin, KVKK"

cd ../musteri-adi
bash scripts/web/status.sh .
```

Brief yoksa `mode=discovery` kalır → IDE `/kesfet` veya elle `DISCOVERY.md`, sonra:

```bash
bash scripts/web/mode.sh promote .
bash scripts/web/state.sh start .
```

Hız şeridi (aynı kapı, iz bırakır):

```bash
bash scripts/web/mode.sh from-brief . "Kısa iş özeti …"
```

`state.sh start` / `orchestrate` / `decide` **factory olmadan RED**. Expert bypass yok.

---

## 2) State + karar + handoff (factory)

```bash
bash scripts/web/status.sh .
# P1 domain-report (/web-baslat veya orchestrate)
bash scripts/web/decide.sh .
# Modülleri kopyala (LLM’den önce)
bash scripts/web/module-apply.sh .
# P2 hybrid (önerilen)
P2_HUMAN_ASSIST=true bash scripts/web/orchestrate.sh . --auto
```

Her oturum başı:

1. `bash scripts/web/status.sh .` (veya `DISCOVERY.md` + `mode.json`)
2. `RUN-STATUS.md`
3. `.factory/web-state.json`
4. `.factory/domain-report.json`
5. `.factory/decision.json`

---

## 3) IDE fark etmez — aynı kapılar

| İş | Cursor | OpenCode | Claude / Antigravity / terminal |
|----|--------|----------|----------------------------------|
| Tek giriş | `/webrail` | `/webrail` | `webrail.sh` |
| Keşif | `/kesfet` | `/kesfet` | `mode.sh from-brief` |
| P1 | `/web-baslat` | `/web-baslat` | `orchestrate` + decide |
| Yama | `/yama` | `/yama` | qa-gate + düzelt |
| QA | `/web-denetle` | `/web-denetle` | `qa-gate.sh` |
| Paket | `/web-yukle` | `/web-yukle` | `package-yukleme.sh` |

---

## 4) Token ekonomisi

| Mekanizma | Dosya |
|-----------|--------|
| Tek giriş / hızlı keşif | `webrail.sh` · `mode.sh from-brief` |
| Karar ucuz / üretim pahalı | `decide.sh` → `decision.json` |
| Modül önce, LLM sonra | `module-apply.sh` + `.factory/modules/*` |
| Bağlam budama | `context_allowlist` |
| Hybrid P2 | `P2_HUMAN_ASSIST=true` |

---

## 5) Personel değişimi

```bash
bash scripts/web/status.sh .
cat RUN-STATUS.md
bash scripts/web/orchestrate.sh . --auto
```

`RUN-STATUS.md` ve `.factory/*` commit’lenir — sohbet hafızasına güvenilmez.
