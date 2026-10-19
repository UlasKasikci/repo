-- Webrail notifications — TR-ASCII: bildirimler
CREATE TABLE IF NOT EXISTS `bildirimler` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `kullanici_id` BIGINT UNSIGNED NOT NULL,
  `title` VARCHAR(190) NOT NULL,
  `body` TEXT NULL,
  `okundu` TINYINT(1) NOT NULL DEFAULT 0,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_bildirimler_kullanici` (`kullanici_id`),
  KEY `idx_bildirimler_okundu` (`okundu`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
