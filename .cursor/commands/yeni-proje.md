# /yeni-proje — Tam Fabrika Bootstrap

## Project Intent Gate (ön koşul)

`/yeni-proje` ve `init-new-app.sh` yalnızca `workspace_role=android-app` ve `platform=android` ile çalışır. `package_name` zorunludur.

Ön kontrol:

```bash
python3 scripts/governance/validate-project-intent.py --mode genesis --require-role android-app
```

Intent yoksa veya rol uyumsuzsa → **BLOCKED** — önce `/prompt-genesis`.

---

Yeni Android uygulaması: iskelet + governance + YAPILACAKLAR.

## Kullanım

Kullanıcı app adı ve package vermişse kullan; yoksa sor:
- Uygulama adı
- Package (`com.sirket.app`)
- Kısa ürün açıklaması (prompt)

## Sıra

1. `./scripts/init-new-app.sh "<AppName>" "<package>"` (terminal)
2. `/baslat` akışı — promptu `YAPILACAKLAR.md` kaynak satırına yaz
3. F0'dan devam — **F1 kodu F0 bitene kadar yok**

## Çıktı

Bootstrap özeti + ilk Cursor prompt önerisi (33 katman).
