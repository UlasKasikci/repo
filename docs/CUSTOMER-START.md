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
bash scripts/web/guard.sh matrix .   # neye izin var / fix yolu
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

1. `bash scripts/web/status.sh .`
2. `RUN-STATUS.md` + `PHASE-LOG.md`
3. `.factory/web-state.json` · `mode.json`
4. `.factory/domain-report.json` · `decision.json`

Oturum sonu:

```bash
bash scripts/web/phase-log.sh . "ne yaptım" "ne kaldı" "OpenCode|Cursor|Claude|Antigravity"
bash scripts/web/run-status.sh .
```

---

## 3) IDE fark etmez — aynı kapılar

Detay playbook: [`docs/IDE-HANDOFF.md`](IDE-HANDOFF.md)  
(Örn. OpenCode’da P1–P2 → Cursor’da P3–P5 paket.)

| İş | Cursor | OpenCode | Claude / Antigravity / terminal |
|----|--------|----------|----------------------------------|
| Tek giriş | `/webrail` | `/webrail` | `webrail.sh` |
| Keşif | `/kesfet` | `/kesfet` | `mode.sh from-brief` (+ PLAN.md) |
| P1 | `/web-baslat` | `/web-baslat` | `orchestrate` + decide |
| Doctor | `/doktor` | `/doktor` | `doctor.sh --loop` (QA FAIL’de auto) |
| Denetim / gap | `/denetle` | `/denetle` | `denetle.sh` (P1/P3/P5 auto) |
| Yama | `/yama` | `/yama` | qa-gate + düzelt |
| QA | `/web-denetle` | `/web-denetle` | `qa-gate.sh` |
| Paket | `/web-yukle` | `/web-yukle` | `package-yukleme.sh` |
| Handoff log | `phase-log.sh` | aynı | aynı |

Android / YAPILACAKLAR komutları **yok** — kullanma.

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

---

## 5b) QA FAIL → Error Doctor

```bash
bash scripts/web/doctor.sh . --qa-first   # teşhis
bash scripts/web/doctor.sh . --loop       # güvenli düzeltmeler + qa yeniden
# Kalan: yalnız FIX-BRIEF.md — IDE /doktor
```

---

## 6) GitHub / push — müşteri projelerinde kilit

Bootstrap sonrası hedef **customer-app** olur (`.factory/workspace-role.json` +
`WEBRAIL-CUSTOMER.md`).

| Kural | Açıklama |
|-------|----------|
| Varsayılan | `git push` **yasak** — kullanıcı açıkça demedikçe |
| Fabrika remote | `UlasKasikci/repo` **asla** bağlanmaz / push edilmez |
| Kontrol | `bash scripts/web/guard.sh git-push .` → DENY |
| Dağıtım | `qa-gate` PASS → `Yukleme/` → FTP (GitHub zorunlu değil) |

Açık kullanıcı komutu + kendi ürün remote’u varsa:

```bash
bash scripts/web/guard.sh git-push .   # önce DENY olmamalı (fabrika URL yok)
WEBRAIL_ALLOW_GIT_PUSH=1 git push -u origin main
```

Fabrika deposunu (`~/webrail`) bozmamak için müşteri ağacında `origin` fabrika URL’si
ise hemen kaldırın: `git remote remove origin`.
