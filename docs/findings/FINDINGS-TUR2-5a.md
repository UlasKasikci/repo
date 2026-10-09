# FINDINGS — Tur 2-5a: Reasoning Cap Config Fix + Pilot İterasyon

**Tarih:** 2026-10-09 · **Commit hedefi:** `opencode.json` (provider fix) + bu dosya
**Kök neden varsayımı (Tur 2-4):** GLM-5.3 `reasoning_effort` default **max**; reasoning token'ları
`max_tokens` toplam cap'ini yiyor → 6 P2 oturumunun 4'ünde `reasoning=32000, output=0`, tool call yok.
**Bu tur kararı (brief):** config ile düzelt (K7: config-only izole test, A2'' YOK), pilot koş, karar ağacı.

---

## 1. Config syntax yolculuğu (brief maddesi 1-2)

| Deneme | Key | Sonuç |
|--------|-----|-------|
| 1 | `providers` (çoğul) + `options.reasoning_effort` + `limit` | **YÜKLENMEDİ**: `level=WARN … path=["providers"] kind=unsupported action="Omitted native setting that cannot be represented in V1"` |
| 2 | `provider` (tekil) — aynı alt blok | **YÜKLENDİ**: `opencode debug config` provider bloğunu gösteriyor; WARN yok |

- Şema kanıtı: `https://opencode.ai/config.json` → root `$defs/Config.properties` içinde
  **`provider`** (tekil) var; `providers` (çoğul) V2 key'i, V1'de omit edilir.
- `body` key'i şemada **yok** (brief'te önerilmişti) — atlandı. `options` free-form → API body'ye geçer.
- `limit` şeması: `{context, output}` **ikisi zorunlu** (`additionalProperties:false`).
  GLM-5.3: context **1,048,576**, max output 128K (Z.AI + NIM dokümanları).
- NIM referansı `reasoning_effort` (low/high/max, default max) destekliyor; GLM-5.3'te
  `low`/`high`/`max` dışındaki değer **error**.
- Trivial run doğrulaması (config öncesi): `reasoning=0, output=3` — tekil prompt için
  ayırt edici değil (max cap bir MAX, sabit yanma değil). Asıl kanıt pilot 2'dir.

**Nihai config (`opencode.json`):**

```json
"provider": {
  "nvidia": {
    "models": {
      "z-ai/glm-5.3": {
        "options": { "reasoning_effort": "high" },
        "limit": { "context": 1048576, "output": 65536 }
      }
    }
  }
}
```

**Operasyon notu:** `opencode debug config` config'i doğrular ama **uyarımları basmayabilir**;
`--print-logs --log-level DEBUG` ile `configuration compatibility` WARN'i **yoklamak** şarttır
(brief maddesinin ruhu: "config yüklenmiyorsa E2E başlatma" — bu turda pilot 1 bu yüzden
geçersiz bir config testi oldu, aşağıda).

---

## 2. Pilot 1 (22:53Z, config YÜKLENMEMİŞ — geçersiz config testi, değerli bulgu F2)

- Kurulum: bootstrap + tur2-3 `domain-report.json`/`project-intent.json` kopyası, `--p2-only`,
  max_attempts=1, idle_max=900, outer 900s TERM.
- Not: ilk launch tool-timeout process-group kill'iyle öldü; relaunch `start_new_session=True`
  ile detach edildi (gelecek turlar için standart).
- Attempt 1: tool timeout kill (rc=143, metrics kill-safe) — turn verisi yok.
- Attempt 2: **rc=0, 477s, 1 step, write=0.**
  - reasoning=**11397** (cap altında — doğal varyans, config etkisi DEĞİL çünkü config omit edilmişti)
  - Araçlar: `read` domain-report ✓ → `bash` (state.sh + ls -laR keşif) → **RED**
  - Hata: `The user rejected permission to use this specific tool call.`
  - **F2 (yeni bulgu):** model bash `workdir` parametresine **typo** yazdı
    (`…178klgxs675c7ntwd3nlyc…` — gerçek: `…wdvw3nlyc…`); izin reddi = oturum **halt**
    (Tur 2-3'te workdir her zaman doğruydu → 22 bash completed; red yolu hiç görülmemişti).
  - İkincil: model turn'ü tool hatasından sonra sürdürmedi (permission-reddi = "user stop" semantiği).

## 3. Pilot 2 (23:12Z, config YÜKLÜ — asıl config testi)

- Aynı kurulum, yeni bootstrap (provider-key'li şablon), detach launch.
- **WARN yok** (providers-omitted bir daha görülmedi) + `debug config` provider bloğu görünür.
- Sonuç: **rc=143 (outer budget 900s), steps=3, retry=0, write=0.**

| Metrik | Tur 2-3 (cap'siz) | Pilot 2 (high) |
|--------|-------------------|----------------|
| reasoning / step | **32000** (4/6 oturumda cap) | **410 → 210 → 16917** |
| output / step | **0** (cap yiyince) | **141 → 202 → 279** (hepsi >0) |
| tool call | tool'suz kapanış | read×1 + bash×3 **completed** |
| cache_read | — | 34240 (cache çalışıyor) |

- Model davranışı: domain-report'un tek-satır JSON'unu read-tool truncation'ı nedeniyle
  "kesilmiş" gördü → bash ile python json extraction workaround'ı (Tur 2-3'ün 22 bash çağrısıyla
  aynı davranış) → metin: *"…aralık okuma ile çekip hemen yazma dalgasına geçiyorum"*,
  *"…Argon2id seed hash'i ve araç durumu aynı çağrıda alıyorum — ardından…"*
  → **yazma dalgası tam başlayacakken**…
- **F3 (yeni bulgu):** 23:19:25'te **boş assistant message** (out=0, reas=0) + ardından
  **8 dk provider stream hang** (token akışı sıfır, süreç canlı, opencode timeout yok) →
  outer budget TERM. Yazma dalgası hiç başlamadı.

## 4. Hükm brief karar ağacına göre

- **H1 (32k reasoning cap) KAPANDI:** config yüklendiğinde reasoning/step 410–16917 aralığına
  indi, output sürekli >0, tool call'lar döndü. Cap tuzağı reproduce edilmedi.
- **Config testi PASS.** Ancak brief'ün pilot kabulü "write devam ediyor" → **write=0** ile
  **tam PASS verilemez**; kalan iki engel H1'den FARKLI ve dar:
  - **F2:** workdir typo → izin reddi → halt (pilot 1; model-hata dayanıklılığı)
  - **F3:** provider stream hang, opencode'un timeout'u yok (pilot 2; altyapı)
- Karar ağacı: "Pilot FAIL → A2'' + devam stratejisi, sonra tekrar pilot" — **F3 teşhisi
  A2'''den ÖNCE** (prompt fix asılı request'i kesmez; F3 varsa A2'' pilotu da asılır).

## 5. Öneriler (sıralı, sonraki tur kararına)

1. **F3 teşhis (önce — altyapı):** stream hang için opencode timeout env/flag araştırması
   (`request timeout`, reconnect) + driver-side remedy: idle watchdog zaten 900s'te TERM
   veriyor; **retry prompt'unda "önceki adımı tekrarlama, kaldığın yerden UYGULA"** bağlanabilir
   (Tur 2-4 önerisiyle aynı aile). Hang-2xx mi hang-frozen mı — HTTP seviyesi log gerekli
   (`--print-logs DEBUG` pilot 3'te).
2. **F2 hafifletme (prompt, ucuz):** P2 prompt'una "bash workdir parametresi KULLANMA
   (proje kökü default'tur)" — typo olasılığını sıfırla.
3. **A2'' tasarımı (K7 ayrı tur):** tool'suz kapanış yasağı + "dalga duyurusu ≠ dalga" +
   sürdürme kuralı — F2/F3 kalıcı olursa.
4. **Tekrar pilot (Tur 2-5b):** F3 remedy + F2 prompt satırı ile; brief kabulü yazma dalgası.

## 6. Kabul kriterleri (bu tur)

| Kriter | Sonuç |
|--------|-------|
| config yüklü (WARN yok + debug config provider görünür) | **PASS** |
| reasoning cap'e çarpmadı (max/step << 32000) | **PASS** (16917 max) |
| output > 0 | **PASS** |
| tool call'lar döndü (read/bash completed) | **PASS** |
| turn tool'suz kapanmadı | **PASS** (kapanış budget kill; boş-msg+hang = F3) |
| write > 0 (brief pilot kabulü) | **FAIL** (F3 yazma dalgasını kesti) |
| A2'' EKLENMEDİ (K7) | **PASS** |
| QA gate/state graph değişmedi (K6) | **PASS** |

**Sırada (kullanıcı kararı):** F3 remedy + F2 prompt satırı → Tur 2-5b tekrar pilot ·
veya doğrudan A2''+devam stratejisi tasarımı.
