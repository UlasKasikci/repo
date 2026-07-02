# YAPILACAKLAR — {{APP_NAME}}

> **Bina metaforu:** Zemin → taşıyıcı → katlar → tesisat → cephe → iç mekan → anahtar teslim  
> **Halüsinasyon sıfır:** Her madde dosya/kanıt referansı içerir; uydurma yasak.  
> **Protokol:** `.cursor/rules/00-overmind-zero-hallucination.mdc`

| Alan | Değer |
|------|-------|
| Proje | {{APP_NAME}} |
| Package | `{{PACKAGE_NAME}}` |
| Fabrika sürümü | v{{FACTORY_VERSION}} |
| Oluşturulma | {{DATE}} |
| Aktif faz | **F0 — Zemin & Temel** |
| Aktif ajanlar | *(validate-yapilacaklar.py ile otomatik — `governance/phase-agents.json`)* |
| Kaynak prompt | *(Geliştirici promptu buraya)* |

---

## F0 — Zemin & Temel (Governance + MCP + Hafıza) · `işleniyor`

| # | Görev | Ajan | L1 | Kabul | Durum |
|---|-------|------|----|-------|-------|
| F0.0 | Project intent: `python3 scripts/governance/validate-project-intent.py --mode genesis` | Overmind | CEO | workspace_role/platform explicit user confirmation ile kilitli; domain-specific işlem doğru intent ile uyumlu | bekliyor |
| F0.1 | `./scripts/first-setup.sh` + `./scripts/check-mcp.sh` | MCP | Baş Mimar | P0 MCP yeşil | bekliyor |
| F0.2 | `./scripts/governance/init-governance.sh` | CEO | CAO | sprint lock + approval queue | bekliyor |
| F0.3 | `docs/00-INDEX.md` proje adıyla uyumlu | Overmind | CEO | INDEX güncel | bekliyor |
| F0.4 | `YAPILACAKLAR.md` kaynak prompt dolduruldu | Overmind | CEO | prompt satırı dolu | bekliyor |
| F0.5 | Hiyerarşik zincir doğrulama: `python3 scripts/governance/validate-audit-chain.py` | CAO | CEO | exit 0 | bekliyor |

**F0 çıkış kapısı:** Tüm satırlar `tamamlandı` → F1 `işleniyor`

---

## F1 — Kolon & Taşıyıcı (Vizyon + Pazar + Monetizasyon) · `bekliyor`

| # | Görev | Ajan | L1 | Kabul | Durum |
|---|-------|------|----|-------|-------|
| F1.1 | `docs/01-VISION/PRODUCT_BRIEF.md` doldur | CPO | PDC | brief onaylı | bekliyor |
| F1.2 | `docs/01-VISION/MARKET_ANALYSIS.md` — rakip kanıtı (web/MCP) | CPO | PDC | kaynaklı analiz | bekliyor |
| F1.3 | `docs/01-VISION/MONETIZATION.md` | CPO | PDC | model tanımlı | bekliyor |
| F1.4 | PDC roadmap taslak: `governance/product_decision/roadmap_priorities.json` | PDC | CAO | P0 net | bekliyor |

**F1 çıkış kapısı:** CPO + PDC L1 onayı

---

## F2 — Kat Döşeme (Mimari & Modül Haritası) · `bekliyor`

| # | Görev | Ajan | L1 | Kabul | Durum |
|---|-------|------|----|-------|-------|
| F2.1 | `docs/02-ARCHITECTURE/MODULE_MAP.md` | Baş Mimar | CEC | modül listesi | bekliyor |
| F2.2 | `docs/02-ARCHITECTURE/DATA_FLOW.md` | Baş Mimar | CEC | akış diyagramı | bekliyor |
| F2.3 | `governance/dependency-rules.json` package uyumu | Baş Mimar | Denetçi | {{PACKAGE_NAME}} | bekliyor |
| F2.4 | ArchUnit / mimari script (varsa) | Denetçi | CAO | ihlal yok | bekliyor |

---

## F3 — Duvar & Tesisat (Android İskelet) · `bekliyor`

| # | Görev | Ajan | L1 | Kabul | Durum |
|---|-------|------|----|-------|-------|
| F3.1 | Gradle 10 modül iskeleti doğrula | Android Elite | Baş Mimar | build ok | bekliyor |
| F3.2 | Hilt + Room + Navigation iskelet | Android Elite | Baş Mimar | derleme | bekliyor |
| F3.3 | i18n `assets/locales/tr.json`, `en.json` boş şablon | Android Elite | CPO | hard-coded yok | bekliyor |

---

## F4 — Cephe & UI (Compose + Liquid Glass) · `bekliyor`

| # | Görev | Ajan | L1 | Kabul | Durum |
|---|-------|------|----|-------|-------|
| F4.1 | Design system / tema (standartlara uygun) | Android Elite | CPO | 33 katman UI | bekliyor |
| F4.2 | Ana ekran iskeleti (MVP loop) | Android Elite | Baş Mimar | Compose preview | bekliyor |
| F4.3 | Tablet/adaptive layout kontrol | Android Elite | CPO | responsive | bekliyor |

---

## F5 — Elektrik & Güvenlik (Denetim + OEM) · `bekliyor`

| # | Görev | Ajan | L1 | Kabul | Durum |
|---|-------|------|----|-------|-------|
| F5.1 | `./scripts/factory-health.sh` | Denetçi | CAO | skor raporu | bekliyor |
| F5.2 | Güvenlik checklist (`docs/03-STANDARDS/SECURITY.md`) | Denetçi | Baş Mimar | bulgu kapalı | bekliyor |
| F5.3 | OEM matris taraması (hedef cihaz varsa) | OEM Denetçi | Denetçi | matris | bekliyor |

---

## F6 — Ölçüm & Analitik (AID Sprint P) · `bekliyor`

| # | Görev | Ajan | L1 | Kabul | Durum |
|---|-------|------|----|-------|-------|
| F6.1 | `SPRINT_P_EVENT_CATALOG.json` proje olayları | AID | CAO | minimum_events | bekliyor |
| F6.2 | Analytics pipeline + session tracker | AID | CAO | kod mevcut | bekliyor |
| F6.3 | Cihaz kanıtı / gate ACTIVE | AID | CEO | gate json ACTIVE | bekliyor |

---

## F7 — İç Mekan & İnce İşçilik (Feature WP'ler) · `bekliyor`

| # | Görev | Ajan | L1 | Kabul | Durum |
|---|-------|------|----|-------|-------|
| F7.1 | `governance/executive/APPROVAL_QUEUE.md` WP'ler sırayla | CDID | CEC | L1+L2 onay | bekliyor |
| F7.2 | Roadmap P0 feature implementasyonu | Android Elite | CEC | reality score ↑ | bekliyor |

*Geliştirici promptundan türeyen ek WP'ler buraya `[EK-YYYYMMDD]` ile eklenir.*

---

## F8 — Anahtar Teslim (Hiyerarşik kapanış) · `bekliyor`

| # | Görev | Ajan | L1 | Kabul | Durum |
|---|-------|------|----|-------|-------|
| F8.1 | `python3 scripts/cao/run_cao_audit.py` | CAO | CEO | rapor | bekliyor |
| F8.2 | `./scripts/ceo/run_ceo_cycle.sh` | CEO | CSGB | cycle ok | bekliyor |
| F8.3 | `./scripts/agent-approval-gate.sh` | Overmind | Geliştirici | gate pass | bekliyor |
| F8.4 | `docs/CHANGELOG.md` + release notları | CEO | EGC | ADR güncel | bekliyor |

---

## Keşifler & Dinamik Eklemeler

Uygulama sırasında tespit edilen eksikler (otomatik veya ajan önerisi):

| Ek ID | Faz | Görev | Neden | Durum |
|-------|-----|-------|-------|-------|
| — | — | *(henüz yok)* | — | — |

---

## Durum Özeti

| Faz | Ad | Durum |
|-----|-----|-------|
| F0 | Zemin & Temel | işleniyor |
| F1 | Kolon & Taşıyıcı | bekliyor |
| F2 | Kat Döşeme | bekliyor |
| F3 | Duvar & Tesisat | bekliyor |
| F4 | Cephe & UI | bekliyor |
| F5 | Elektrik & Güvenlik | bekliyor |
| F6 | Ölçüm & Analitik | bekliyor |
| F7 | İç Mekan | bekliyor |
| F8 | Anahtar Teslim | bekliyor |

**Son güncelleme:** {{DATE}} · **Güncelleyen ajan:** Overmind
