# /web-yukle — Paketleme & Dağıtım Kapısı (P5)

Agent 5 · `27-web-packaging` — `Yukleme/` üretimi ve teslim raporu.

## Ön kapı (zorunlu)

```bash
bash scripts/web/state.sh status            # faz P5 olmalı
grep '"result"' qa-report.json              # PASS olmalı
```

Faz P5 değilse `/web-denetle` çalıştır; PASS yoksa **paketleme yasak**.

## Komut

```bash
bash scripts/web/package-yukleme.sh .
cat packaging-report.json
```

Script önce `qa-gate.sh`'i tekrar koşar; FAIL ise `Yukleme/` hiç oluşmaz.

## Doğrulama

```bash
find Yukleme -maxdepth 3 | sort            # §14 ağaç
grep -c 'FOREIGN KEY' Yukleme/SQL/veritabani.sql
```

- Ağaç birebir: `assets/{css,js,images}`, `core/`, `views/`, `SQL/veritabani.sql`,
  `.htaccess`, `index.php`, `robots.txt`, `sitemap.xml`
- denylist sızıntısı varsa rapor `failures` doludur → paketleme FAIL sayılır, düzeltilir.
- Ek üretim dizinleri: `YUKLEME_EXTRA="uploads storage" bash scripts/web/package-yukleme.sh .`

## Teslim raporu

`packaging-report.json` (sha256 manifest + skipped + notes) özetini kullanıcıya sun:
dosya sayısı, byte, SQL durumu, minify notları, FTP hedefi `Yukleme/`.

`Yukleme/` asla commit edilmez (build artifact, `.gitignore`'da).

## Canlı doğrulama (P5 sonrası — raporlayıcı, opsiyonel)

```bash
LIGHTHOUSE_URL=<çalışan_url> bash scripts/web/lighthouse-verify.sh .   # veya --serve
```

`.factory/lighthouse-report.json` üretir: `PASS` / `WARN` (eşik altı — v1'de exit 0,
CI'ı kirletmez) / `SKIPPED` (URL/araç yok). `--strict` sonraki sıkılaştırma için
WARN'i exit 1 yapar. State graph'a girmez, paketleme (`.factory` denylist) girmez.
