-- Webrail payment — TR-ASCII: odemeler (docs/DB-NAMING.md)
CREATE TABLE IF NOT EXISTS `odemeler` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `siparis_id` BIGINT UNSIGNED NOT NULL,
  `provider` VARCHAR(64) NOT NULL DEFAULT 'manual',
  `amount` DECIMAL(12,2) NOT NULL,
  `currency` CHAR(3) NOT NULL DEFAULT 'TRY',
  `status` VARCHAR(32) NOT NULL DEFAULT 'pending',
  `external_id` VARCHAR(128) NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_odemeler_siparis` (`siparis_id`),
  KEY `idx_odemeler_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
