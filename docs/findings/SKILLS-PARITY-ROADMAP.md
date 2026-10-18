# Webrail × AI Agent Skills — Parity & Yükseltme Yol Haritası

**Kaynak inceleme:** [developersglobal.github.io/ai-agent-skills](https://developersglobal.github.io/ai-agent-skills/)  
**Repo:** [DevelopersGlobal/ai-agent-skills](https://github.com/DevelopersGlobal/ai-agent-skills) (30 skill · 8 kategori · MIT)  
**Hedef:** Cursor · OpenCode · Claude Code · Antigravity — **aynı kalite**  
**Tarih:** 2026-10-18 · **Durum:** baş mimar kesiti uygulandı (guard); skill tiyatrosu ertelendi

---

## Baş mimar kesiti (2026-10-18) — gerekli vs gereksiz

### Kaliteyi gerçekten artıran (UYGULANDI)

| Yapı | Neden |
|------|--------|
| `scripts/web/guard.sh` | Yanlış işlemi **DENY** + **fix komutu** + `guard-log.jsonl` audit |
| `guard.sh matrix` + `status.sh` guard satırı | “Ne yapabilirim?” tek ekran — IDE fark etmez |
| Mevcut script kapıları (mode/state/qa/package) | Zaten gerçek denetim; guard bunları **sorgulanabilir** kılar |

**İlke:** Kalite = metin skill sayısı değil; **yanlış adımın kapalı kalması + düzeltme yolunun görünmesi**.

### Ertelenen / gereksiz (şimdilik YAPMA)

| Öneri (eski backlog) | Neden ertele |
|----------------------|--------------|
| 8 kategori + 20 process skill kopyası | Kapıya bağlanmadan doküman şişmesi; denetim artırmaz |
| Skill anatomisi migrate (Rationalizations…) | Estetik; fail-closed davranışı yok |
| IDE’ler arası markdown skill parity | Bootstrap zaten `scripts/web` kopyalar — **script parity = kalite parity** |
| everyday / meeting-notes / rag skill | Webrail teslim barına dokunmaz |
| Ajan çoğaltma (parity için) | Tek onay yasak zaten; yeni ajan ≠ yeni kapı |

### İleride yalnızca şu koşulla

Skill ekle **ancak** `guard.sh` veya `qa-gate` kanalına bağlanırsa (tetik → script).  
Aksi halde ekleme.

---

## 0) Ne öğrendik? (referans model)

AI Agent Skills şu mimariyi dayatıyor:

| Katman | İçerik |
|--------|--------|
| **8 kategori** | `think` → `plan` → `build` → `test` → `review` → `harden` → `ship` → `everyday` |
| **Tek anatomi** | frontmatter (`name`, `description`, `category`, `applies-to`, `version`) + Overview · When to Use · Process · Rationalizations · Red Flags · Verification |
| **IDE-agnostik** | `applies-to: [claude, gemini, cursor, …]` — skill tek yerde, her araca kopyalanır |
| **Süreç skill’i** | “nasıl düşün/planla/test et” (domain kodundan ayrı) |

Webrail’in gücü farklı ve korunmalı: **state graph + qa-gate + module-apply + mode kilidi**.  
Referans modelden alınacak olan: **ortak skill anatomisi + kategori haritası + IDE parity** — 30 skill’i kör kopyalamak değil, Webrail’e uyarlamak.

---

## 1) Bugünkü asimetri (kanıt)

| Yüzey | Cursor | OpenCode | Claude | Antigravity |
|-------|--------|----------|--------|-------------|
| Anayasa | `.cursorrules` | `opencode.json` → CLAUDE/WEB-EDITION | `CLAUDE.md` | `antigravity.yaml` |
| Domain skill | yok (yalnız OC’de) | auth/admin/kvkk/seo | yok | yok (yaml’de “prefer catalog”) |
| Süreç skill | zero-hallucination, AAR, audit, yapilacaklar×2 | yok | yok | yok |
| Komut | 17 | 7 | yok (script) | yok (pipeline) |
| Ajan | 9 | 5 | yok | phase→agent map |

**Sonuç:** Aynı “kalite” iddiası kırık — OpenCode domain’de güçlü, Cursor süreçte güçlü, Claude/Antigravity skill klasörü yok.

---

## 2) Mevcut ↔ 8 kategori eşlemesi (düzenlenecekler)

Aşağıdakiler **silinmez**; kategori + anatomi + ortak köke taşınır.

### THINK
| Mevcut Webrail | Düzenleme |
|----------------|-----------|
| `.cursor/skills/zero-hallucination` | → `skills/process/hallucination-prevention/SKILL.md` (category: think/harden); Claude/OC/AG’ye aynen |
| `/kesfet` + `DISCOVERY.md` + `mode from-brief` | → `skills/process/idea-to-discovery/SKILL.md` (idea-to-spec uyarlaması); komutlar IDE’de ince sarmalayıcı kalsın |
| Intent gate kuralları (`20`/`21`) | Skill’e özet + “When to Use”; kural dosyası kanonik kalsın |

### PLAN
| Mevcut | Düzenleme |
|--------|-----------|
| `decide.sh` / `decision.json` / allowlist | → `skills/process/context-loading/SKILL.md` (Decision Layer’a bağla) |
| `yapilacaklar-planner` (Cursor) | Web Edition’da legacy; → `skills/process/task-decomposition` **web faz diliyle** (P1–P5) veya deprecate + `/webrail` plan adımı |
| `orchestrate.sh` multi-agent | → `skills/process/multi-agent-orchestration/SKILL.md` (Webrail pipeline referansı) |

### BUILD
| Mevcut | Düzenleme |
|--------|-----------|
| `.opencode/skills/{auth,admin,kvkk,seo}` | → `skills/domain/*/SKILL.md` + mevcut `files/` paketleri; **tüm IDE’ler aynı path** |
| `module-apply.sh` | Skill Process adımı 1: “önce module-apply” |
| `/yama` | → `skills/process/surgical-changes/SKILL.md` |
| web-core-engineer ajan | Skill’e “incremental-coding / simplicity-first” Process blokları ekle (ajan kısa kalsın) |

### TEST
| Mevcut | Düzenleme |
|--------|-----------|
| `qa-gate.sh` (14 kanal) | → `skills/process/qa-gate-contract/SKILL.md` (When/Verification); script tek gerçek kapı |
| `self-test.sh` / `p2-checklist` | Skill’te Verification checklist’e bağla |
| *(yok)* debugging-methodology | **Yeni** — P4 revision skill |

### REVIEW
| Mevcut | Düzenleme |
|--------|-----------|
| `hierarchical-audit` / phase-verifier | → `skills/process/code-review-webrail/SKILL.md` + L1 zinciri |
| `/cevap` after-action | → `skills/process/after-action-review` (zaten var; ortak köke) |

### HARDEN
| Mevcut | Düzenleme |
|--------|-----------|
| `29-security.mdc` + qa security_* | → `skills/process/security-hardening-php/SKILL.md` (OWASP Webrail alt kümesi) |
| CSRF/PDO/Argon kuralları | Domain skill + harden skill çapraz ref |
| *(yok)* prompt-injection-defense | **Yeni** — ajan prompt’larına |

### SHIP
| Mevcut | Düzenleme |
|--------|-----------|
| `package-yukleme.sh` / P5 | → `skills/process/production-packaging/SKILL.md` |
| CI `validate.yml` | → `skills/process/ci-cd-webrail/SKILL.md` (kısa) |
| *(kısmi)* git-workflow | Bootstrap commit kuralı skill’e |

### EVERYDAY
| Mevcut | Düzenleme |
|--------|-----------|
| `status.sh` / RUN-STATUS | → `skills/process/session-handoff/SKILL.md` |
| *(yok)* research-and-summarize | Opsiyonel; keşif şeridine bağlanabilir |

---

## 3) Yer almayan özellikler (eklenecekler) — hiyerarşi

Öncelik: **P0 kapı / parity → P1 anatomi → P2 süreç skill → P3 domain genişleme → P4 ölçüm**.

### P0 — Tek kanonik skill kökü + IDE parity (kademe ↑↑)

1. **`skills/` kanonik kök** (veya `.factory/skills/`)  
   - Alt: `process/` + `domain/`  
   - Cursor/OpenCode/Claude/Antigravity buradan **symlink veya bootstrap kopyası** alır.  
   - Yasak: skill’in yalnız bir IDE klasöründe yaşaması.

2. **Parity matrisi (zorunlu)**  
   Her skill için `applies-to: [cursor, opencode, claude, antigravity]`.  
   Self-test: dört yüzeyde path veya mount kontrolü.

3. **Komut parity (minimum set)**  
   OpenCode’a eksikler (Cursor’da var, OC’de yok):  
   `web-faz`, `cevap`/`after-action`, `status` (veya webrail status), isteğe bağlı `denetle`.  
   Claude: `CLAUDE.md` içine skill kökü + `/webrail` eşdeğer bash tablosu.  
   Antigravity: `antigravity.yaml` → `skills_root` + phase başına skill id listesi.

4. **Ajan parity**  
   OpenCode’a (veya paylaşılan köke): `hallucination-guard`, `phase-verifier` (readonly) — veya skill ile karşıla, ajan çoğaltma.

### P1 — Skill anatomisi standardı (kademe ↑)

5. **SKILL.md şablon kontratı** (`.factory/contracts/skill.schema` veya docs şablon):  
   Zorunlu bölümler: Overview · When to Use · Process · Rationalizations · Red Flags · Verification.  
   Frontmatter: `name`, `description`, `category`, `applies-to`, `version`, `webrail_phase` (`A0|P1|P2|P3|P4|P5|ANY`).

6. **Mevcut 4 domain + 5 süreç skill’ini şablona migrate et**  
   İçerik aynı; bölüm başlıkları hizalanır. `preflight` READY kontrolü anatomiyi de tarar.

7. **Katalog** `.factory/modules/catalog.json` genişletmesi veya `skills/catalog.json`:  
   `category` + `package` + `skill` + `phase` tek harita.

### P2 — Süreç skill’leri (referanstan uyarla, Webrail’leştir)

| # | Eklenecek skill | Kaynak ilham | Webrail bağ |
|---|-----------------|--------------|-------------|
| 8 | `think-before-coding` | think-before-coding | A0/P2 öncesi; mode=discovery ile çelişmesin |
| 9 | `goal-driven-execution` | goal-driven-execution | acceptance_criteria ↔ domain-report |
| 10 | `idea-to-discovery` | idea-to-spec | DISCOVERY.md + from-brief |
| 11 | `context-loading` | context-loading | decision allowlist + read whitelist |
| 12 | `incremental-coding` | incremental-coding | P2 batch-yaz / tek-turn iskelet |
| 13 | `surgical-changes` | surgical-changes | `/yama` |
| 14 | `debugging-methodology` | debugging-methodology | P4 + debug_report.json |
| 15 | `ai-output-validation` | ai-output-validation | qa-gate + domain-check |
| 16 | `security-hardening-php` | security-hardening | PDO/CSRF/XSS/oturum |
| 17 | `prompt-injection-defense` | prompt-injection-defense | ajan system prompt |
| 18 | `production-packaging` | production-deployment | Yukleme/ P5 |
| 19 | `session-handoff` | (everyday) | status + RUN-STATUS |

**Alınmayacak / ertele (Webrail dışı veya düşük ROI):**  
rag-and-memory, meeting-notes-to-tasks, generic frontend-engineering (zaten web-frontend ajan), full TDD framework (PHPUnit kapısı var; skill ince tutulabilir).

### P3 — Domain skill genişleme

20. **`cart-order` skill + paket** (catalog’da skill:null → doldur)  
21. **`error-handling-php`** (harden) — anlamlı HTTP/JSON hata şeması  
22. **`observability-basics`** — request log / metrics.jsonl okuma rehberi  
23. **`api-design-php-mvc`** — REST JSON sözleşme (core engineer ile)

### P4 — Doğrulama & kalite eşitleme

24. **`scripts/web/skills-parity.sh`** — dört IDE mount + anatomi + catalog drift  
25. **preflight’a ek kanal** — skill READY + applies-to + category  
26. **Self-test** — her yeni process skill için en az 1 senaryo (varlık + frontmatter)  
27. **README IDE matrisi** — skill/komut/ajan parity tablosu (CUSTOMER-START ile senkron)

---

## 4) Düzenleme kuralları (nasıl taşıyalım)

```text
BUGÜN                          HEDEF
.opencode/skills/domain-*  →  skills/domain/*          (OC/Cursor/Claude/AG mount)
.cursor/skills/process-*   →  skills/process/*         (aynı)
CLAUDE.md (yalnız özet)    →  + skills_root pointer
antigravity.yaml           →  + skills: [...] per phase
.cursor/commands/*         →  ince wrapper (skill’e delege)
.opencode/command/*        →  aynı wrapper seti (parity)
```

- **Tek kaynak, çok mount:** bootstrap `skills/` kopyalar; IDE-native path’ler symlink veya kopya.  
- **Kapı gevşemez:** skill “düşün” der; `qa-gate` / `mode` / `max_retries` script’te kalır.  
- **Kör kopya yasak:** her skill Webrail fazına (`webrail_phase`) ve PHP/MySQL yığınına bağlanır.

---

## 5) Önerilen uygulama sırası (sprint)

| Sprint | Çıktı | Dur kapısı |
|--------|--------|------------|
| **S1** | ~~tam `skills/` kök~~ → **S1-light DONE:** bootstrap `.opencode/skills` → `.cursor/skills` mount + `guard`/`module-apply` kapı | preflight + self-test 77+ |
| **S2** | Komut/ajan parity (OC + CLAUDE.md + antigravity.yaml) | dört IDE smoke checklist |
| **S3** | P2 process skill’leri 8–19 (önce 8,9,11,13,16) | self-test + doküman |
| **S4** | Domain cart + harden/observability | module-apply + qa kanalları |
| **S5** | Ölçüm: skill tetiklenme metrics; README parity tablosu | müşteri koşusu |

---

## 6) Başarı ölçütü (kademe yukarı ne demek?)

| Metrik | Bugün | Hedef |
|--------|-------|-------|
| Domain skill IDE kapsamı | 1/4 (yalnız OC) | **4/4** |
| Süreç skill IDE kapsamı | 1/4 (yalnız Cursor) | **4/4** |
| Ortak komut seti (webrail çekirdek) | OC 7 / Cursor 17 | **çekirdek ≥10, dört IDE** |
| SKILL anatomi uyumu | 0% (bölüm yok) | **100% process+domain** |
| Saf IDE süreç kalitesi farkı | yüksek asimetri | **aynı kapı + aynı skill metni** |

---

## 7) Bilinçli sınır

- 30 skill’in tamamı Webrail’e taşınmaz; **web teslim + state graph** ile çakışanlar öncelikli.  
- Android/legacy yapilacaklar skill’leri Web Edition’da ya map edilir ya deprecate.  
- Ücretli JEV / harici skill marketplace bağımlılığı yok — içerik MIT uyarlanabilir, kanonik repo `UlasKasikci/repo`.
