# TUR 3-1 VERIFICATION — v1.2 Fix Turu (CSRF OOP + CONTRACTS Sandbox)

**Tarih:** 2026-10-12 · **Kapsam:** F1 + F2 + F3 (stop rule: yalnız bu 3 fix)
**Bağlam:** 3 gerçek proje PASS (envanter 4.8sa, randevu 27dk, helpdesk 34dk);
v1.2 adayları n=3 saha kanıtlı, spekülatif değil.

---

## F1 — CONTRACTS Sandbox (commit `f192397`)

**Sorun:** `orchestrate.sh:26` `CONTRACTS="$ROOT/.factory/contracts"` — P1 prompt'una
fabrika kökündeki **mutlak** yol yazılıyordu; opencode sandbox dış dizin iznini
auto-reject ediyor → domain-report üretilemiyor → exit 3.

**Saha kanıtı:**
- helpdesk-app: P1 deneme 1+2 **auto-reject** (20k token israf, ~40 sn) → 3. deneme başarılı
- randevu-app: 0 auto-reject (ajan şans eseri proje-içi kopyayı kullandı — stokastik)
- envanter-app: CONTRACTS fix öncesi — aynı risk altında ama şans eseri kaçmadı

**Fix:** PROJECT tanımlandıktan sonra proje-içi kopya varsa override:
```bash
[[ -d "$PROJECT/.factory/contracts" ]] && CONTRACTS="$PROJECT/.factory/contracts"
```
(bootstrap zaten `$PROJECT/.factory/contracts/` altına şemaları kopyalıyor.)

**P1 attempt-1 oranı (F4 — izleme notu):** CONTRACTS fix sonrası P1 attempt-1 başarı
oranı **sonraki (dördüncü) projede** ölçülecek. Bu turda yeni proje yok (stop rule).
Beklenti: auto-reject israfları sıfırlanır, P1 tek deneme normu 1'e döner.

## F2 — CSRF_CALL_RE OOP deseni (qa-gate.sh)

**Sorun:** gate `csrf_verify(`/`check_csrf(` yakalıyordu; OOP desenler
(`Csrf::verify(`, `Csrf::requireValid(`, `Csrf::check(`, `$this->csrf->verify(`)
kaçıyordu. **helpdesk-app /register POST'ta CSRF hiç yoktu** (routing'te
`Csrf::requireValid()` çağrısı eksikti) — gate desen blindspot'u yüzünden PASS aldı;
manuel P4 düzeltmesiyle yakalandı. 3/3 run'da kanıtlandı (envanter'da bilinen kısıt,
randevu'da helper'a çevrildi, helpdesk'te gerçek açık).

**Fix:** `CSRF_CALL_RE` genişletildi (aynı set_check: security_policy, K6 7→7):
```
(csrf[_-]?verify|verify[_-]?csrf|check[_-]?csrf|Csrf::verify|Csrf::requireValid|Csrf::check|csrf->verify)[[:space:]]*\(
```
Hata mesajı artık **dosya:satır** raporluyor:
`POST endpoint'te CSRF çağrısı yok: <dosya>:<satır>`

**Negatif/pozitif fixture doğrulaması (self-test 63-64):**
- `tests/fixtures/good_csrf_oop.php` — `Csrf::verify`/`Csrf::requireValid` dosyası → **PASS**
- `tests/fixtures/bad_csrf_register.php` — helpdesk /register açığının birebir kopyası → **FAIL** + satır numarası

## F3 — P2 Prompt CSRF Guard (web-core-engineer ×2)

**Sorun:** gate geçse bile P2 ajanı CSRF'i unutabiliyor (helpdesk'te unuttu).

**Fix:** `.cursor/agents/web-core-engineer.md` + `.opencode/agent/web-core-engineer.md`
değişmez güvenlik kuralına eklendi:
> Her POST controller'ında ilk satırda `guardPost()` veya `Csrf::requireValid()`
> çağrısı ZORUNLU. CSRF'siz POST kabul edilmez.

**Self-test 65:** iki agent dosyasında zorunlu ifadenin varlığı grep ile doğrulanır.

## Kısıt uyumu

| Kısıt | Durum |
|---|---|
| K1 hard-kill yok | ✓ |
| K6 set_check 7→7 | ✓ (security_policy güçlendi, sayı değişmedi) |
| K7 ayrı commit | ✓ F1 `f192397`; F2+F3 tek tur fix (gate+prompt+test birbirine bağımlı — birlikte commit) |
| K8 silme yok | ✓ |
| Stop rule | ✓ yalnız 3 fix |
| self-test 63 → ≥66 | ✓ 66 (51/52 A.4/A.3 mesaj regresyonu da güncellendi) |

## Sonuç

- F1 commit'li + CI yeşil
- F2 gate genişletildi + fixture'lar + satır numarası + self-test 63/64
- F3 prompt ×2 + self-test 65
- **v1.2 tag** — "CSRF OOP desen + /register açığı kapatıldı"
