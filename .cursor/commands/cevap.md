# /cevap

Bu command, Cursor işlem özetini APP-FABRIKA governance açısından değerlendirir.

## Kullanım

Kullanıcı Cursor işlem özetini `/cevap` ile verir (yapılan değişiklikler, komutlar, faz, riskler).

## Ön Koşul

Bu command **DIAGNOSTIC / AAR** modudur. **Dosya değiştirme yapmaz.**

Önce şu kontrolleri değerlendir (okuma veya mevcut özetten):

```bash
python3 scripts/governance/validate-project-intent.py --mode diagnostic
python3 scripts/governance/validate-yapilacaklar.py
```

Gerekirse:

```bash
python3 scripts/governance/validate-audit-chain.py
```

**Skill:** `.cursor/skills/after-action-review/SKILL.md`  
**Contract:** `docs/CEVAP_REPORT_CONTRACT.md`

## Görev

Kullanıcıdan gelen Cursor işlem özetini `docs/CEVAP_REPORT_CONTRACT.md` formatına göre değerlendir.

Şunları kontrol et:

1. Intent uyumu
2. Domain/platform uyumu
3. YAPILACAKLAR aktif faz uyumu
4. Kullanıcı onayı gereken değişiklikler
5. Security/privacy riski
6. Architecture boundary riski
7. Design/accessibility etkisi
8. Validation kanıtı
9. Rollback notu
10. Eksik bilgiler
11. Sonraki hiyerarşik adım

## Yasaklar

- Dosya değiştirme
- Script çalıştırıp remediation yapma
- Feature implementation başlatma
- Scaffold oluşturma
- Commit atma
- Yeni faza geçme
- Kullanıcı onayı olmadan sonraki promptu uygulama

## Output

`docs/CEVAP_REPORT_CONTRACT.md` içindeki **`/CEVAP REVIEW REPORT`** formatını kullan.

Son bölümde **`Cursor'a Verilecek Sonraki Prompt`** başlığında kopyalanabilir tek `text` bloğu üret.
