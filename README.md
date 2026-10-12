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
| Doğrulama | self-test **66/66** · CI · 14 kanallı QA gate |
| Sürüm | **v1.2** (CSRF OOP + sandbox + P2 guard) |

[![CI](https://github.com/UlasKasikci/repo/actions/workflows/validate.yml/badge.svg)](https://github.com/UlasKasikci/repo/actions/workflows/validate.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![self-test](https://img.shields.io/badge/self--test-66%2F66%20PASS-brightgreen.svg)](scripts/web/self-test.sh)

> Bu depo kendi kendine yeterlidir. Tek remote: `origin` → `UlasKasikci/repo`.
> Başka bir GitHub org/repo’ya bağımlılık veya push yolu yoktur.

---

## Ne işe yarar?

| Problem | Webrail cevabı |
|---------|----------------|
| Farklı AI araçlarında dağınık süreç | Ortak `.factory/` state + IDE-agnostik kontratlar |
| Eksik RBAC / KVKK / sepet / SEO | P1 proaktif domain denetimi (`module_matrix`) |
| “Yeşil görünen” güvensiz kod | P3: 14 kontrol, **0 Error / 0 Warning** olmadan paket yok |
| Token israfı (aynı blokları yeniden üretmek) | Model routing, bağlam budama, pattern reuse, metrik (`metrics.jsonl`) |
| Dağıtıma hazır olmayan çıktı | P5: staging → smoke → `Yukleme/` + sha256 manifest |

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
bash scripts/web/self-test.sh          # 66/66 PASS beklenir

# Yeni müşteri/proje iskeleti
bash scripts/web/bootstrap-project.sh ../musteri-projesi --yes
cd ../musteri-projesi
bash scripts/web/state.sh start .
# ardından IDE'de /kur + /web-baslat veya:
bash scripts/web/orchestrate.sh . --auto
bash scripts/web/qa-gate.sh .
bash scripts/web/package-yukleme.sh .  # yalnız QA PASS sonrası
```

Çıkış kodları: `0` OK · `1` FAIL · `2` HALT · `3` orkestratör beklemede (LLM adımı).

---

## Depo yapısı

```text
webrail/   (= bu repo: UlasKasikci/repo)
├── .cursor/                 # Cursor kuralları, ajanlar, komutlar
├── .opencode/               # OpenCode ajan/komut/skill
├── .factory/
│   ├── contracts/           # P1 / P3 / P5 JSON şemaları
│   ├── web-state-graph.json # Faz makinesi
│   └── meta.json            # Ürün kimliği
├── scripts/web/             # state, orchestrate, qa-gate, package, self-test…
├── docs/                    # WEB-EDITION, MASTER-PROMPT, findings
├── tests/fixtures/          # Pozitif/negatif QA fixture’ları
├── CLAUDE.md                # Claude Code direktifleri
└── .cursorrules             # Cursor anayasası
```

---

## Kanıtlanmış saha

| Sürüm | Kanıt | Özet |
|-------|-------|------|
| **v1.0** | envanter-app | Kalite: 4s 48dk, QA PASS, DONE |
| **v1.1** | randevu-app | Hız (benzer domain): **27 dk**, pattern reuse |
| **v1.2** | helpdesk-app + çift AI denetimi | CSRF OOP + `/register` kapısı + CONTRACTS sandbox + P2 guard; self-test 66/66 |

v1.2 release: [github.com/UlasKasikci/repo/releases/tag/v1.2](https://github.com/UlasKasikci/repo/releases/tag/v1.2)

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

## İzlenen adaylar (v1.x / v1.3)

Bunlar spekülatif değil; saha notlarından gelen adaylar:

- `--allow-no-cart` semantiğinin domain-aware netleştirilmesi
- P4 ajan yazma yeteneğinin ek kanıtı
- P1 attempt-1 fail oranının müşteri koşusunda izlenmesi

Yeni QA kontrolü yalnız somut bug ile eklenir (K6).

---

## Katkı

1. Yalnız bu depoda çalışın: `https://github.com/UlasKasikci/repo`
2. PR öncesi: `bash scripts/web/self-test.sh` → **66/66 PASS** ve CI yeşil
3. Doküman güncellemesi kanıttan türer (K5)

## Lisans

[MIT](LICENSE) © 2026 UlasKasikci
