# Webrail

**Çoklu yapay zekâ için web denetim ve tüketim kontrol düzlemi.**

Webrail; Cursor, OpenCode ve Claude Code üzerinde aynı kontratları okuyan
deterministik bir faz hattıdır. Amaç hız vaadi değil: her PHP/MySQL web
projesinin aynı denetim kapılarından geçmesi, eksik modül/güvenlik boşluklarının
üretimden önce yakalanması ve tekrarlayan işlerde token tüketiminin düşürülmesi.

| | |
|---|---|
| Kanonik depo | [`github.com/UlasKasikci/repo`](https://github.com/UlasKasikci/repo) |
| Stack | PHP 8.1+ (framework’süz MVC) · MySQL 8 / MariaDB · HTML/CSS/JS · FTP/`Yukleme/` |
| Doğrulama | self-test **70/70** · `preflight.sh` · CI · 14 kanallı QA gate |
| Sürüm | **v1.3** (Decision Layer + READY skills + müşteri öncesi preflight) |

[![CI](https://github.com/UlasKasikci/repo/actions/workflows/validate.yml/badge.svg)](https://github.com/UlasKasikci/repo/actions/workflows/validate.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![self-test](https://img.shields.io/badge/self--test-70%2F70%20PASS-brightgreen.svg)](scripts/web/self-test.sh)

> Bu depo kendi kendine yeterlidir. Tek remote: `origin` → `UlasKasikci/repo`.
> Başka bir GitHub org/repo’ya bağımlılık veya push yolu yoktur.

---

## Ne işe yarar?

| Problem | Webrail cevabı |
|---------|----------------|
| Farklı AI araçlarında dağınık süreç | Ortak `.factory/` state + IDE-agnostik kontratlar |
| Eksik RBAC / KVKK / sepet / SEO | P1 proaktif domain denetimi (`module_matrix`) |
| “Yeşil görünen” güvensiz kod | P3: 14 kontrol, **0 Error / 0 Warning** olmadan paket yok |
| Token israfı (aynı blokları yeniden üretmek) | **Decision Layer** (`decide.sh`): modül önce, bağlam allowlist, ucuz/pahalı model ayrımı |
| IDE / personel değişimi | `RUN-STATUS.md` + `.factory/*` — sohbet hafızasına güvenilmez |
| Dağıtıma hazır olmayan çıktı | P5: staging → smoke → `Yukleme/` + sha256 manifest |

**Ücretli JEV yok.** JEV’in “karar ucuz / üretim pahalı” mantığı açık kaynak
`scripts/web/decide.sh` ile uygulanır. Müşteri açılışı: [`docs/CUSTOMER-START.md`](docs/CUSTOMER-START.md).

---

## Nasıl çalışır?

```text
START → P1 Domain → P2 Code → P3 QA ──PASS──→ P5 Package → DONE
                          │
                          ├─ FAIL (retry 1–3) → P4 Revision → P3
                          └─ 4. FAIL → HALT + debug_report.json
```

| Faz | Ajan | Kapı |
|-----|------|------|
| P1 | Domain Architect | `domain-report.json` (şema doğruluğu) |
| P2 / P4 | Core Engineer (+ Frontend) | Yapısal iskelet; asıl kapı P3 |
| P3 | QA Gatekeeper (`readonly`) | `qa-gate.sh` exit 0 |
| P5 | Deploy Packager | `packaging-report.json` → `Yukleme/` |

Tek ajan onayı yok: P1→P2 yalnız domain raporuyla, P3→P5 yalnız QA PASS ile.

Kanonik spesifikasyon: [`docs/WEB-EDITION.md`](docs/WEB-EDITION.md) ·
Strateji / K1–K8: [`docs/MASTER-PROMPT-V2.md`](docs/MASTER-PROMPT-V2.md)

---

## Hızlı başlangıç

```bash
git clone https://github.com/UlasKasikci/repo.git
cd repo

composer global require phpstan/phpstan phpunit/phpunit
bash scripts/web/self-test.sh          # 70/70 PASS beklenir
bash scripts/web/preflight.sh          # müşteri öncesi READY kapısı

# Yeni müşteri/proje iskeleti (fabrika köküne YAZMA)
bash scripts/web/bootstrap-project.sh ../musteri-projesi --yes
cd ../musteri-projesi
bash scripts/web/state.sh start .
# P1 sonrası otomatik: decision.json + RUN-STATUS.md
bash scripts/web/orchestrate.sh . --auto
# veya elle: bash scripts/web/decide.sh .
bash scripts/web/qa-gate.sh .
bash scripts/web/package-yukleme.sh .  # yalnız QA PASS sonrası
```

Her oturum: önce `RUN-STATUS.md` oku. Çıkış: `0` OK · `1` FAIL · `2` HALT · `3` bekleme.

---

## Depo yapısı

```text
webrail/   (= bu repo: UlasKasikci/repo)
├── .cursor/                 # Cursor kuralları, ajanlar, komutlar
├── .opencode/               # OpenCode ajan/komut/skill
├── .factory/
│   ├── contracts/           # P1 / P3 / P5 / decision şemaları
│   ├── modules/             # katalog → skill (Decision Layer)
│   ├── web-state-graph.json # Faz makinesi
│   └── meta.json            # Ürün kimliği
├── scripts/web/             # state, decide, run-status, orchestrate, qa-gate…
├── docs/                    # WEB-EDITION, CUSTOMER-START, MASTER-PROMPT
├── tests/fixtures/          # Pozitif/negatif QA fixture’ları
├── CLAUDE.md · antigravity.yaml · .cursorrules
└── RUN-STATUS.md            # (müşteri projesinde üretilir — handoff)
```

---

## Kanıtlanmış saha

| Sürüm | Kanıt | Özet |
|-------|-------|------|
| **v1.0** | envanter-app | Kalite: 4s 48dk, QA PASS, DONE |
| **v1.1** | randevu-app | Hız (benzer domain): **27 dk**, pattern reuse |
| **v1.2** | helpdesk-app + çift AI denetimi | CSRF OOP + `/register` + CONTRACTS sandbox |
| **v1.3** | Decision Layer + skills READY | JEV-mantık (ücretsiz) + RUN-STATUS + preflight + 4 skill; self-test 70/70 |

Release: [v1.2](https://github.com/UlasKasikci/repo/releases/tag/v1.2) · [v1.3](https://github.com/UlasKasikci/repo/releases/tag/v1.3) (bu tur)

---

## Güvenlik ve denetim (özet)

- SQL: yalnız PDO prepared statement
- XSS: `htmlspecialchars(..., ENT_QUOTES, 'UTF-8')`
- CSRF: her POST’ta `guardPost()` / `Csrf::requireValid()` / `Csrf::verify()` (gate OOP desenini tanır)
- Parola: `PASSWORD_ARGON2ID` veya `PASSWORD_BCRYPT` (cost ≥ 12)
- Oturum: HttpOnly · Secure · SameSite
- KVKK/GDPR: aydınlatma + çerez rızası (compliance açıkken zorunlu)

---

## Ortam değişkenleri (sık kullanılan)

| Değişken | Rol |
|----------|-----|
| `MODEL_P1` / `MODEL_P2` / `MODEL_P4` | Faz bazlı model routing |
| `STRICT_*` | `--strict` token/duvar bütçesi |
| `QA_GATE_EXTRA` | örn. `--allow-no-cart` (onaylı istisna) |
| `P2_HUMAN_ASSIST=true` | P2 hybrid (iskeleti insan, P3–P5 otomatik) |

---

## Müşteri öncesi kapanış

Fabrika tarafı hazır kabul edilir:

- `bash scripts/web/preflight.sh` → **READY**
- Skills: auth-rbac · admin-crud · kvkk-compliance · seo-basics (**READY**)
- Decision Layer + RUN-STATUS + CUSTOMER-START dokümanı

Saha ölçümü (P1 fail oranı, P4 yazma) **ilk müşteri koşusunda** toplanır — fabrika açık uç değil.

Yeni QA kontrolü yalnız somut bug ile eklenir (K6).

---

## Katkı

1. Yalnız bu depoda çalışın: `https://github.com/UlasKasikci/repo`
2. PR öncesi: `preflight.sh` READY + `self-test.sh` → **70/70 PASS** + CI yeşil
3. Doküman güncellemesi kanıttan türer (K5)

## Lisans

[MIT](LICENSE) © 2026 UlasKasikci
