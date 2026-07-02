#!/usr/bin/env bash
set -euo pipefail

# Yeni Android projesi başlatır — GitHub template klonundan sonra çalıştırın.
# Kullanım: ./scripts/init-new-app.sh "UygulamaAdi" "com.sirket.uygulama"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

APP_NAME="${1:-}"
PACKAGE_NAME="${2:-}"
FACTORY_VERSION="$(python3 -c "import json; print(json.load(open('$ROOT/.factory/meta.json'))['version'])")"

if [[ -z "$APP_NAME" || -z "$PACKAGE_NAME" ]]; then
  echo "Kullanım: $0 <UygulamaAdi> <com.sirket.uygulama>"
  exit 1
fi

python3 "$ROOT/scripts/governance/validate-project-intent.py" \
  --mode genesis --require-role android-app || exit 2

SLUG="$(echo "$APP_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-')"
DATE="$(date +%Y-%m-%d)"

echo "==> Yeni uygulama başlatılıyor: $APP_NAME ($PACKAGE_NAME)"

# --- 00-INDEX güncelle ---
cat > "$ROOT/docs/00-INDEX.md" <<EOF
# OTONOM TEKNOLOJİ HOLDİNGİ — SİSTEM HAFIZASI

## Durum

| Alan | Değer |
|------|-------|
| Aktif Proje | **$APP_NAME** |
| Package | \`$PACKAGE_NAME\` |
| Faz | 0 — Vizyon & Pazar Araştırması |
| Fabrika Sürümü | v$FACTORY_VERSION |
| Son Güncelleme | $DATE |

## Hızlı Bağlantılar

| Belge | Durum |
|-------|-------|
| [PRODUCT_BRIEF](./01-VISION/PRODUCT_BRIEF.md) | 🟡 Şablon — CPO dolduracak |
| [MARKET_ANALYSIS](./01-VISION/MARKET_ANALYSIS.md) | ⬜ Bekliyor |
| [MONETIZATION](./01-VISION/MONETIZATION.md) | ⬜ Bekliyor |
| [MODULE_MAP](./02-ARCHITECTURE/MODULE_MAP.md) | 🟡 Şablon — Mimar dolduracak |
| [ANDROID_STRUCTURE](./02-ARCHITECTURE/ANDROID_STRUCTURE.md) | ✅ Standart |
| [33 Katman](./33-LAYER-ARCHITECTURE.md) | ✅ Aktif |
| [BOOTSTRAP](./BOOTSTRAP.md) | ✅ Kurulum kılavuzu |

## Mimar Komut Akışı

\`\`\`
1. CPO Ajan    → MARKET_ANALYSIS + PRODUCT_BRIEF + MONETIZATION
2. Mimar Ajan  → MODULE_MAP + DATA_FLOW
3. Android     → Kod (Compose, i18n, Hilt, Room)
4. Auditor     → Denetim
\`\`\`

## İlk Cursor Promptu

> $APP_NAME uygulamasını 33 katman standartlarına göre geliştir.
> Package: $PACKAGE_NAME
EOF

# --- PRODUCT_BRIEF ---
sed -e "s/{{APP_NAME}}/$APP_NAME/g" \
    -e "s/{{PACKAGE_NAME}}/$PACKAGE_NAME/g" \
    -e "s/{{APP_DESCRIPTION}}/Henüz tanımlanmadı — CPO Ajanı dolduracak/g" \
    -e "s/{{FACTORY_VERSION}}/$FACTORY_VERSION/g" \
    "$ROOT/templates/vision/PRODUCT_BRIEF.template.md" > "$ROOT/docs/01-VISION/PRODUCT_BRIEF.md"

# --- MARKET_ANALYSIS placeholder ---
cat > "$ROOT/docs/01-VISION/MARKET_ANALYSIS.md" <<EOF
# Pazar Analizi — $APP_NAME

> CPO Ajanı web search ile doldurur. Kod yazılmadan önce tamamlanmalı.

## Top 10 Rakip

| # | Rakip | Güçlü Yön | Zayıf Yön (Acı Noktası) |
|---|-------|-----------|-------------------------|
| 1 | | | |

## Mavi Okyanus Fırsatları

1.

## Kullanıcı Acı Noktaları (Yorum Analizi)

-
EOF

# --- MONETIZATION placeholder ---
cat > "$ROOT/docs/01-VISION/MONETIZATION.md" <<EOF
# Monetizasyon — $APP_NAME

## Model

- 7 gün ücretsiz deneme (abonelik başlangıcında fatura bağlantısı)
- Aylık / Yıllık plan

## Bölgesel Fiyatlandırma

| Bölge | Aylık | Yıllık |
|-------|-------|--------|
| US | \$X.XX | \$XX.XX |
| TR | ₺X | ₺XX |

## Premium Özellikleri

1.

## Paywall Konumu

*(En heyecanlı an — CPO belirler)*
EOF

# --- MODULE_MAP ---
sed -e "s/{{APP_NAME}}/$APP_NAME/g" \
    "$ROOT/templates/architecture/MODULE_MAP.template.md" > "$ROOT/docs/02-ARCHITECTURE/MODULE_MAP.md"

# --- OEM_TEST_REPORT ---
sed -e "s/{{APP_NAME}}/$APP_NAME/g" \
    "$ROOT/templates/architecture/OEM_TEST_REPORT.template.md" > "$ROOT/docs/02-ARCHITECTURE/OEM_TEST_REPORT.md"

# --- SECURITY ---
sed -e "s/{{APP_NAME}}/$APP_NAME/g" \
    "$ROOT/templates/architecture/SECURITY.template.md" > "$ROOT/docs/02-ARCHITECTURE/SECURITY.md"

# --- DATA_FLOW placeholder ---
cat > "$ROOT/docs/02-ARCHITECTURE/DATA_FLOW.md" <<EOF
# Veri Akışı — $APP_NAME

## V1 (Offline-First)

\`\`\`
UI → ViewModel → UseCase → Repository → Room (SQLCipher)
                                      → JSON Assets (seed data)
\`\`\`

## V2 (API — Gelecek)

\`\`\`
Repository → Local (Room) + Remote (REST)
           → SyncQueue (conflict resolver)
\`\`\`

## Sync Stratejisi

- V1: Yok (tamamen local)
- V2: Last-write-wins + kullanıcı onayı (kritik veri)
EOF

# --- TODO sıfırla ---
cat > "$ROOT/docs/TODO.md" <<EOF
# TODO — $APP_NAME

## Aktif Fazlar

- [ ] **Faz 0:** Vizyon & Pazar — CPO Ajanı MARKET_ANALYSIS + PRODUCT_BRIEF
- [x] **Faz 1:** Mimari iskelet — MODULE_MAP + Android modülleri (scaffold)
- [ ] **Faz 2:** V1 MVP — Offline-first, Compose, i18n
- [ ] **Faz 3:** Denetim — Auditor onayı
- [ ] **Faz 4:** Premium & Monetizasyon

## Yeni Fazlar

## Giderilmesi Gereken Hatalar

## Tamamlanan

- [x] Fabrika bootstrap — $DATE
EOF

# --- PENTEST ---
sed -e "s/{{APP_NAME}}/$APP_NAME/g" \
    "$ROOT/templates/architecture/PENTEST_CHECKLIST.template.md" > "$ROOT/docs/02-ARCHITECTURE/PENTEST_REPORT.md"

# --- Android mimari iskeleti (tam modül yapısı) ---
bash "$ROOT/scripts/scaffold-android-project.sh" "$APP_NAME" "$PACKAGE_NAME"

# --- Proje meta ---
mkdir -p "$ROOT/.factory"
cat > "$ROOT/.factory/project.json" <<EOF
{
  "app_name": "$APP_NAME",
  "package_name": "$PACKAGE_NAME",
  "slug": "$SLUG",
  "factory_version": "$FACTORY_VERSION",
  "initialized_at": "$DATE"
}
EOF

# --- Executive OS (CEO V7) ---
bash "$ROOT/scripts/governance/init-governance.sh" "$APP_NAME" "$PACKAGE_NAME" "$SLUG"

# --- YAPILACAKLAR (hiyerarşik faz planı) ---
bash "$ROOT/scripts/governance/init-yapilacaklar.sh"

# --- MCP hatırlatma ---
echo ""
echo "  MCP: ./scripts/check-mcp.sh (P0: Browser + GitHub)"
echo "  Kılavuz: docs/MCP_SETUP.md"

echo "==> Bootstrap tamamlandı."
echo ""
echo "  Uygulama : $APP_NAME"
echo "  Package  : $PACKAGE_NAME"
echo "  Slug     : $SLUG"
echo ""
echo "Sonraki adım — Cursor'da:"
echo "  \"$APP_NAME uygulamasını 33 katman standartlarına göre geliştir.\""
