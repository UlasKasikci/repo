-- Webrail cart — TR-ASCII (docs/DB-NAMING.md): siparisler
CREATE TABLE IF NOT EXISTS `siparisler` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `kullanici_id` BIGINT UNSIGNED NOT NULL,
  `status` VARCHAR(32) NOT NULL DEFAULT 'pending',
  `total` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  `currency` CHAR(3) NOT NULL DEFAULT 'TRY',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_siparisler_kullanici` (`kullanici_id`),
  KEY `idx_siparisler_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `siparis_kalemleri` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `siparis_id` BIGINT UNSIGNED NOT NULL,
  `urun_id` BIGINT UNSIGNED NOT NULL,
  `quantity` INT UNSIGNED NOT NULL DEFAULT 1,
  `unit_price` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  PRIMARY KEY (`id`),
  KEY `idx_siparis_kalemleri_siparis` (`siparis_id`),
  KEY `idx_siparis_kalemleri_urun` (`urun_id`),
  CONSTRAINT `fk_siparis_kalemleri_siparis` FOREIGN KEY (`siparis_id`) REFERENCES `siparisler` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
