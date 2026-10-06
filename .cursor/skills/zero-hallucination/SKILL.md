---
name: zero-hallucination
description: >-
  Halüsinasyon sıfır protokolü. Her dosya/API/script referansından önce okuma/grep
  zorunlu. YAPILACAKLAR ve hiyerarşik denetim kapısı. Yeni oturum, kod yazımı,
  dosya referansı veya "tamamlandı" iddiası öncesi otomatik uygula.
---

# Halüsinasyon Sıfır Protokolü

## Tetikleyiciler

- Yeni proje veya yeni oturum
- Dosya/sınıf/script adı söylenmeden önce
- "Tamamlandı", "hazır", "çalışıyor" iddiası
- Governance veya `.cursor` yapılandırması

## Zorunlu adımlar

1. **Okumadan yazma:** Referans verilen her path için `Read`, `Glob` veya `Grep` kanıtı.
2. **YAPILACAKLAR kapısı:** `YAPILACAKLAR.md` yoksa `bash scripts/governance/init-yapilacaklar.sh` veya `/baslat`.
3. **Tek aktif faz:** Birden fazla faz `işleniyor` olamaz.
4. **Komut kanıtı:** Script iddiası → terminal çıktısı veya dosya satır referansı.
5. **Uydurma yasak:** Package adı, modül listesi, JSON alanları — repodan oku.

## Doğrulama checklist

- [ ] Path gerçekten var mı?
- [ ] İçerik iddia ile uyumlu mu?
- [ ] Aktif faz `YAPILACAKLAR.md` ile uyumlu mu?
- [ ] L1 denetim yapıldı mı (tek ajan onayı yok)?

## Hata durumunda

Dur, uydurmayı bırak, eksik dosyayı oluştur veya Mimar'a sor.
