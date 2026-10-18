# Webrail

**Çoklu yapay zekâ için web denetim ve tüketim kontrol düzlemi.**

Webrail; Cursor, OpenCode ve Claude Code üzerinde aynı kontratları okuyan
deterministik bir faz hattıdır. Amaç hız vaadi değil: her PHP/MySQL web
projesinin aynı denetim kapılarından geçmesi, eksik modül/güvenlik boşluklarının
üretimden önce yakalanması ve tekrarlayan işlerde token tüketiminin düşürülmesi.

| | |
|---|---|
| Fabrika deposu | [`github.com/UlasKasikci/repo`](https://github.com/UlasKasikci/repo) |
| Stack | PHP 8.1+ (framework’süz MVC) · MySQL 8 / MariaDB · HTML/CSS/JS · FTP/`Yukleme/` |
| Doğrulama | self-test **79/79** · `preflight` · `guard` · **doctor** (hata→düzelt) · 14 kanallı QA |
| Sürüm | **v1.3** · Şerit A · Decision Layer · git-push kilidi · Error Doctor |

[![CI](https://github.com/UlasKasikci/repo/actions/workflows/validate.yml/badge.svg)](https://github.com/UlasKasikci/repo/actions/workflows/validate.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![self-test](https://img.shields.io/badge/self--test-79%2F79%20PASS-brightgreen.svg)](scripts/web/self-test.sh)

> **Fabrika** (`role=webrail-factory`): tek remote `origin` → `UlasKasikci/repo`.  
> **Müşteri / ürün** (`bootstrap` → `role=customer-app`): asla fabrika remote’una bağlanmaz;
> `git push` varsayılan **yasak** — yalnız kullanıcı açıkça isterse
> (`WEBRAIL_ALLOW_GIT_PUSH=1` + `guard.sh git-push`). Dağıtım = `Yukleme/` → FTP.

---

## Ne işe yarar?

| Problem | Webrail cevabı |
|---------|----------------|
| Farklı AI araçlarında dağınık süreç | Ortak `.factory/` state + IDE-agnostik kontratlar |
| Eksik RBAC / KVKK / sepet / SEO | P1 proaktif domain denetimi (`module_matrix`) + `module-apply` |
| “Yeşil görünen” güvensiz kod | P3: 14 kontrol, **0 Error / 0 Warning** olmadan paket yok |
| Token israfı (aynı blokları yeniden üretmek) | **Decision Layer** (`decide.sh`): modül önce, bağlam allowlist |
| IDE / personel değişimi | `RUN-STATUS.md` + `.factory/*` — sohbet hafızasına güvenilmez |
| Ajan yanlışlıkla fabrika GitHub’ına push | `workspace-role` + `guard.sh git-push` DENY (müşteri ağacı) |
| QA FAIL → “ne bozuk / nasıl düzeltilir?” | **`doctor.sh`**: tarif eşle → safe apply → `FIX-BRIEF.md` (token-ucuz) |
| Dağıtıma hazır olmayan çıktı | P5: staging → smoke → `Yukleme/` + sha256 manifest |

**Ücretli JEV yok.** JEV’in “karar ucuz / üretim pahalı” mantığı açık kaynak
`scripts/web/decide.sh` ile uygulanır. Müşteri açılışı: [`docs/CUSTOMER-START.md`](docs/CUSTOMER-START.md).

---

## Nasıl çalışır?

```text
/kesfet (discovery) → mode.sh promote → P1 Domain → P2 Code → P3 QA ──PASS──→ P5 → DONE
                                              │
                                              ├─ FAIL (retry 1–3) → P4 → P3
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
git clone https://github.com/UlasKasikci/repo.git ~/webrail
cd ~/webrail

composer global require phpstan/phpstan phpunit/phpunit
bash scripts/web/self-test.sh    # 79/79
bash scripts/web/preflight.sh    # READY

# Tek giriş — fabrika köküne YAZMA; hedef customer-app olur
bash scripts/web/webrail.sh ../musteri-projesi --yes \
  --brief "Demo: auth + admin + KVKK panel"
cd ../musteri-projesi
bash scripts/web/status.sh .
bash scripts/web/guard.sh matrix .   # git-push → DENY

# P1 → decide → modül kopya → hybrid P2 → QA → paket
# QA FAIL olursa: /doktor  veya  bash scripts/web/doctor.sh . --loop
# /web-baslat · module-apply.sh · P2_HUMAN_ASSIST=true orchestrate.sh --auto
```

Müşteri ağacında GitHub’a yükleme **yok** (varsayılan). Bak: `WEBRAIL-CUSTOMER.md`,
[`docs/CUSTOMER-START.md`](docs/CUSTOMER-START.md) §6.

İleri seviye: `/kesfet`, `mode.sh promote`, `/yama`. Demo için saf IDE; teslim için Webrail.  
Çıkış: `0` OK · `1` FAIL · `2` HALT · `3` bekleme.

---

## Depo yapısı

```text
webrail/   (= fabrika: UlasKasikci/repo)
├── .cursor/                 # kurallar, ajanlar, komutlar (+ bootstrap’ta skills mount)
├── .opencode/               # ajan / komut / domain skills
├── .factory/
│   ├── contracts/           # P1 / P3 / P5 / decision şemaları
│   ├── modules/             # katalog + paketler (auth-rbac, kvkk, admin-crud, seo)
│   ├── workspace-role.json  # fabrika: webrail-factory
│   ├── workspace-role.customer.json  # bootstrap şablonu → customer-app
│   ├── web-state-graph.json # faz makinesi
│   └── meta.json
├── scripts/web/             # webrail, guard, doctor, status, mode, module-apply, qa-gate…
├── docs/                    # WEB-EDITION, CUSTOMER-START, MASTER-PROMPT
├── tests/fixtures/
├── CLAUDE.md · antigravity.yaml · .cursorrules
└── (müşteri ağacında) WEBRAIL-CUSTOMER.md · RUN-STATUS.md
```

---

## Kanıtlanmış saha

| Sürüm | Kanıt | Özet |
|-------|-------|------|
| **v1.0** | envanter-app | Kalite: 4s 48dk, QA PASS, DONE |
| **v1.1** | randevu-app | Hız (benzer domain): **27 dk**, pattern reuse |
| **v1.2** | helpdesk-app + çift AI denetimi | CSRF OOP + `/register` + CONTRACTS sandbox |
| **v1.3** | Decision + guard + doctor | Şerit A · modüller · git-push kilidi · **Error Doctor** · self-test 79/79 |

Release: [v1.2](https://github.com/UlasKasikci/repo/releases/tag/v1.2) · [v1.3](https://github.com/UlasKasikci/repo/releases/tag/v1.3)

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
| `WEBRAIL_ALLOW_GIT_PUSH=1` | Yalnız kullanıcı açıkça “push” dediğinde; önce `guard.sh git-push` |

### Error Doctor (özgün)

```bash
bash scripts/web/doctor.sh . --qa-first   # teşhis + FIX-BRIEF.md
bash scripts/web/doctor.sh . --loop       # güvenli tarifleri uygula → qa yeniden (max 3)
```

IDE: `/doktor` (Cursor + OpenCode). Kanıt: `doctor-report.json`.  
Katalog skill sitelerinden fark: metin playbook değil — **qa-report → script tarif**.

---

## Müşteri öncesi kapanış

Fabrika tarafı hazır kabul edilir:

- `bash scripts/web/preflight.sh` → **READY** (`role=webrail-factory`)
- Skills: auth-rbac · admin-crud · kvkk-compliance · seo-basics (**READY**)
- Decision Layer + RUN-STATUS + CUSTOMER-START + `/kesfet` + `guard.sh`
- Bootstrap müşteriye `customer-app` + `WEBRAIL-CUSTOMER.md` yazar; fabrika GitHub’ı korunur

Saha ölçümü (P1 fail oranı, P4 yazma) **ilk müşteri koşusunda** toplanır.

Yeni QA kontrolü yalnız somut bug ile eklenir (K6).

---

## Katkı (yalnız fabrika deposu)

1. Bu depoda çalışın: `https://github.com/UlasKasikci/repo` — müşteri ağacından buraya push **yasak**
2. PR / push öncesi: `preflight.sh` READY + `self-test.sh` → **79/79** + `guard.sh git-push` ALLOW
3. Push yalnız açık kullanıcı komutu + `WEBRAIL_ALLOW_GIT_PUSH=1`
4. Doküman güncellemesi kanıttan türer (K5)

## Lisans

[MIT](LICENSE) © 2026 UlasKasikci
