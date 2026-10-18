# PLAN — Webrail hiyerarşik iş planı (P1–P5)

> Brief / DISCOVERY’den üretilir. **Kod değil plan.** Android YAPILACAKLAR kullanılmaz.  
> Güncelleme: ajan iş bitince checkbox + `phase-log.sh`. Denetim: `denetle.sh`.

**Proje:** _(ad)_  
**Brief özeti:** _(1–2 cümle)_  
**Üreten IDE:**  
**Durum:** taslak | donduruldu | işleniyor | tamam  

---

## 0. Ajan matrisi

| Faz | Ajan | Görev (özet) | Kanıt dosyası | Denetçi |
|-----|------|--------------|---------------|---------|
| P1 | web-domain-architect | domain-report + gap uyarıları | `.factory/domain-report.json` | hallucination-guard |
| P2 | web-core-engineer (+ frontend) | MVC iskelet + modüller | `core/` `views/` `SQL/` | phase-verifier |
| P3 | web-qa-gatekeeper | qa-gate 0E/0W | `qa-report.json` | phase-verifier |
| P4 | web-core-engineer | doctor + FIX-BRIEF | `doctor-report.json` | phase-auditor |
| P5 | web-deploy-packager | Yukleme/ | `packaging-report.json` | claim-pass |

---

## P1 — Domain

- [ ] DISCOVERY / PLAN donduruldu
- [ ] RBAC / roller
- [ ] Modül matrisi (auth, admin, sepet, ödeme, yorum, KVKK, SEO…)
- [ ] `domain-report.json` PASS
- [ ] `decide.sh` + `module-apply` (gerekli paketler)

## P2 — Kod

- [ ] module-apply uygulandı
- [ ] index.php · core/ · views/ · SQL/
- [ ] CSRF / PDO / htmlspecialchars / parola politikası
- [ ] state advance → P3

## P3 — QA

- [ ] `qa-gate.sh` PASS
- [ ] `denetle.sh` WARN’lar gözden geçirildi

## P4 — Revision (gerekirse)

- [ ] `doctor.sh --loop`
- [ ] FIX-BRIEF uygulandı
- [ ] qa yeniden PASS

## P5 — Paket

- [ ] `package-yukleme.sh` PASS
- [ ] FTP teslim notu

---

## Proaktif uyarılar (gap-scan)

> Sistem brief’te unutulan ama sektörde zorunlu maddeleri buraya yazar (WARN).

| ID | Bulgu | Önem | Karar |
|----|-------|------|-------|
| | | warn/blocker | kabul / eklenecek / istisna |

---

## Oturum kayıtları

`PHASE-LOG.md` + `bash scripts/web/phase-log.sh . "…" "…" "<IDE>"`
