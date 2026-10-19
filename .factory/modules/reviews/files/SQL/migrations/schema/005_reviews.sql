-- Webrail reviews — TR-ASCII: yorumlar
CREATE TABLE IF NOT EXISTS `yorumlar` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `urun_id` BIGINT UNSIGNED NOT NULL,
  `kullanici_id` BIGINT UNSIGNED NULL,
  `rating` TINYINT UNSIGNED NOT NULL,
  `body` TEXT NULL,
  `status` VARCHAR(32) NOT NULL DEFAULT 'pending',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_yorumlar_urun` (`urun_id`),
  KEY `idx_yorumlar_status` (`status`),
  CONSTRAINT `chk_yorumlar_rating` CHECK (`rating` BETWEEN 1 AND 5)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
